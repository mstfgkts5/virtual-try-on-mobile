import 'dart:convert';

import 'package:flutter/services.dart';

/// Uygulamayla gelen hazır 360° dönüş seti (tools/make_spin_set.py üretir).
class SpinPreset {
  const SpinPreset({required this.titleTr, required this.titleEn, required this.framePaths});

  final String titleTr;
  final String titleEn;
  final List<String> framePaths;

  String title(String languageCode) => languageCode == 'en' ? titleEn : titleTr;

  /// `manifest.json` yoksa veya bozuksa `null` (hazır set kartı gösterilmez).
  static Future<SpinPreset?> load(AssetBundle bundle, {String dir = 'assets/images/spin/demo'}) async {
    try {
      final json = jsonDecode(await bundle.loadString('$dir/manifest.json')) as Map<String, dynamic>;
      final n = json['frames'] as int;
      if (n < 1) return null;
      return SpinPreset(
        titleTr: json['title_tr'] as String,
        titleEn: json['title_en'] as String,
        framePaths: [for (var i = 0; i < n; i++) '$dir/frame_$i.jpg'],
      );
    } catch (_) {
      return null;
    }
  }
}
