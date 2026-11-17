import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/wardrobe_item.dart';

/// Gardırop verisine erişim. Ekranlar bu soyut tipe bağlıdır; testlerde sahte depo verilir.
abstract class WardrobeRepository {
  /// Oturum açmış kullanıcının e-postası; oturum yoksa null.
  String? get currentUserEmail;

  /// Kullanıcının kayıtları, en yeni önce.
  Future<List<WardrobeItem>> fetch();

  /// Sonuç görselini yükler ve kaydeder.
  Future<void> add(Uint8List pngBytes, String category);

  Future<void> delete(WardrobeItem item);

  /// Kullanıcının tüm görsellerini, kayıtlarını ve hesabını kalıcı olarak siler (KVKK md. 7 ve 11).
  Future<void> deleteAccount();
}

/// Oturum yokken kaydetmeye çalışıldığında fırlatılır (ekran çevrili mesaj gösterir).
class NotSignedInException implements Exception {
  const NotSignedInException();
}

/// Silme isteği hata vermeden 0 satır sildiğinde fırlatılır (ör. RLS açık ama silme kuralı yok);
/// aksi halde ekran "silindi" der ve kombin yenilemede geri gelir.
class NothingDeletedException implements Exception {
  const NothingDeletedException();
}

void ensureDeleted(List<dynamic> deletedRows) {
  if (deletedRows.isEmpty) throw const NothingDeletedException();
}

/// `category` sütunu tabloda henüz yoksa PostgREST bu hatalardan birini döndürür.
bool isMissingColumnError(Object error) =>
    error is PostgrestException &&
    (error.code == '42703' || error.code == 'PGRST204' || error.message.contains("'category' column"));

class SupabaseWardrobeRepository implements WardrobeRepository {
  SupabaseWardrobeRepository([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  String? get currentUserEmail => _client.auth.currentUser?.email;

  @override
  Future<List<WardrobeItem>> fetch() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];
    // RLS de kısıtlar; filtre, kuralların henüz kurulmadığı projede başkasının kaydını göstermemek için
    final rows = await _client
        .from('wardrobe')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    final items =
        (rows as List).map((r) => WardrobeItem.fromRow(Map<String, dynamic>.from(r as Map))).toList();
    return Future.wait(items.map(_signed));
  }

  /// Depo özel olduğu için görsel, 1 saat geçerli imzalı URL ile gösterilir.
  /// İmzalama başarısız olursa (ör. depo henüz özel değilse) kayıttaki URL kullanılır.
  static const signedUrlSeconds = 3600;

  Future<WardrobeItem> _signed(WardrobeItem item) async {
    final path = item.storagePath;
    if (path == null) return item;
    try {
      final url = await _client.storage.from(WardrobeItem.bucket).createSignedUrl(path, signedUrlSeconds);
      return item.withDisplayUrl(url);
    } catch (e) {
      debugPrint('[Wardrobe] İmzalı URL alınamadı: $e');
      return item;
    }
  }

  @override
  Future<void> add(Uint8List pngBytes, String category) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const NotSignedInException();

    // Klasör = kullanıcı kimliği: depo kuralı (supabase/setup_wardrobe.sql) yazmayı buna göre kısıtlar
    final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.png';
    final storage = _client.storage.from(WardrobeItem.bucket);
    await storage.uploadBinary(path, pngBytes, fileOptions: const FileOptions(contentType: 'image/png'));
    final row = {'user_id': user.id, 'image_url': storage.getPublicUrl(path), 'category': category};

    try {
      await _client.from('wardrobe').insert(row);
    } catch (e) {
      if (!isMissingColumnError(e)) rethrow;
      // SQL kurulumu henüz çalıştırılmadıysa kategori olmadan kaydet
      debugPrint('[Wardrobe] category sütunu yok, kategorisiz kaydediliyor');
      await _client.from('wardrobe').insert(row..remove('category'));
    }
  }

  @override
  Future<void> delete(WardrobeItem item) async {
    // select(): silinen satırları geri döndürür; boşsa gerçekte hiçbir şey silinmemiştir
    final deleted = await _client.from('wardrobe').delete().eq('id', item.id).select('id');
    ensureDeleted(deleted as List);
    final path = item.storagePath;
    if (path == null) return;
    try {
      await _client.storage.from(WardrobeItem.bucket).remove([path]);
    } catch (e) {
      // Satır silindi; dosya kalırsa kullanıcıya görünmez, işlemi başarısız saymayız
      debugPrint('[Wardrobe] Dosya silinemedi: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const NotSignedInException();

    // 1) Kullanıcı klasöründeki tüm görseller (depo kuralı yalnızca kendi klasörüne izin verir)
    final storage = _client.storage.from(WardrobeItem.bucket);
    final files = await storage.list(path: user.id);
    if (files.isNotEmpty) {
      await storage.remove([for (final f in files) '${user.id}/${f.name}']);
    }
    // 2) Gardırop kayıtları
    await _client.from('wardrobe').delete().eq('user_id', user.id);
    // 3) Hesabın kendisi: supabase/privacy_setup.sql içindeki delete_user() fonksiyonu
    await _client.rpc('delete_user');
    // Yerel oturumu da kapat; sunucuda kullanıcı zaten silindiği için hata yok sayılır
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }
}
