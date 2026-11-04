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
}

/// Oturum yokken kaydetmeye çalışıldığında fırlatılır (ekran çevrili mesaj gösterir).
class NotSignedInException implements Exception {
  const NotSignedInException();
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
    return (rows as List).map((r) => WardrobeItem.fromRow(Map<String, dynamic>.from(r as Map))).toList();
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
    await _client.from('wardrobe').delete().eq('id', item.id);
    final path = item.storagePath;
    if (path == null) return;
    try {
      await _client.storage.from(WardrobeItem.bucket).remove([path]);
    } catch (e) {
      // Satır silindi; dosya kalırsa kullanıcıya görünmez, işlemi başarısız saymayız
      debugPrint('[Wardrobe] Dosya silinemedi: $e');
    }
  }
}
