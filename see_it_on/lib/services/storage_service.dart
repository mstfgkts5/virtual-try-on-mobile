import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Üretilen üst giyim görselini galeriye kaydeder
  Future<bool> saveToGallery(Uint8List bytes, {String? fileName}) async {
    final name = fileName ?? 'SeeItOn_${DateTime.now().millisecondsSinceEpoch}.png';

    // Web'de cihaz galerisi yok; başarılı gibi davranmak yerine false dönülür
    if (kIsWeb) return false;

    try {
      // Galeri erişim iznini kontrol et
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          debugPrint('[StorageService] Galeri izni reddedildi.');
        }
      }

      await Gal.putImageBytes(bytes, name: name);
      return true;
    } catch (e) {
      debugPrint('[StorageService] Galeri kaydetme hatası: $e');

      // Hata durumunda uygulama klasörüne kaydetmeyi dene
      try {
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$name');
          await file.writeAsBytes(bytes);
          debugPrint('[StorageService] Alternatif yola kaydedildi: ${file.path}');
          return true;
        }
      } catch (innerError) {
        debugPrint('[StorageService] Alternatif kayıt hatası: $innerError');
      }
      return false;
    }
  }

  /// Üretilen görseli yerel paylaşım menüsü üzerinden paylaşır
  Future<void> shareOutfit(Uint8List bytes, {String? message}) async {
    final text = message ??
        'SeeItOn ile oluşturduğum yapay zeka destekli sanal kombinimi incele! ✨ #SeeItOn #SanalKabin';

    try {
      final xFile = XFile.fromData(
        bytes,
        name: 'SeeItOn_Outfit_${DateTime.now().millisecondsSinceEpoch}.png',
        mimeType: 'image/png',
      );
      await SharePlus.instance.share(ShareParams(files: [xFile], text: text));
    } catch (e) {
      debugPrint('[StorageService] Paylaşım hatası: $e');
      // Görsel paylaşılamazsa sadece metni paylaşmayı dene
      try {
        await SharePlus.instance.share(ShareParams(text: text));
      } catch (_) {}
    }
  }
}