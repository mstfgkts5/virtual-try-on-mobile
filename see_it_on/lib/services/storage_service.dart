import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Saves image bytes to user photo gallery
  Future<bool> saveToGallery(Uint8List bytes, {String? fileName}) async {
    final name = fileName ?? 'SeeItOn_${DateTime.now().millisecondsSinceEpoch}.png';

    if (kIsWeb) {
      debugPrint('[StorageService] Web gallery download simulated');
      return true;
    }

    try {
      // Check or request gallery access permission
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          debugPrint('[StorageService] Gallery permission denied');
        }
      }

      await Gal.putImageBytes(bytes, name: name);
      return true;
    } catch (e) {
      debugPrint('[StorageService] Gal save error: $e');

      // Fallback: save to application documents or downloads folder
      try {
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$name');
          await file.writeAsBytes(bytes);
          debugPrint('[StorageService] Saved to fallback path: ${file.path}');
          return true;
        }
      } catch (innerError) {
        debugPrint('[StorageService] Secondary fallback error: $innerError');
      }
      return false;
    }
  }

  /// Shares the generated try-on outfit via native share sheet
  Future<void> shareOutfit(Uint8List bytes, {String? message}) async {
    final text = message ??
        'Check out my AI-powered virtual try-on created with SeeItOn! ✨ #SeeItOn #FashionAI #VirtualTryOn';

    try {
      final xFile = XFile.fromData(
        bytes,
        name: 'SeeItOn_Outfit_${DateTime.now().millisecondsSinceEpoch}.png',
        mimeType: 'image/png',
      );
      await Share.shareXFiles([xFile], text: text);
    } catch (e) {
      debugPrint('[StorageService] Share error: $e');
      // Fallback share as text
      try {
        await Share.share(text);
      } catch (_) {}
    }
  }
}
