import 'dart:convert';

import 'package:flutter/services.dart';

/// Çevrimdışı demo: hazır manken × örnek kıyafet çiftleri için önceden üretilmiş sonuçlar.
///
/// Sonuçlar `backend/make_demo_results.py` ile uygulamanın tam ayarıyla (768×1024, 8 adım,
/// kırpma + renk düzeltme) üretilir ve `assets/images/demo/` altına konur. Sunucuya
/// ulaşılamazsa yükleme ekranı bu sonucu gösterebilir; kullanıcının kendi fotoğrafı için
/// hazır sonuç yoktur.
class DemoResult {
  const DemoResult({
    required this.resultAsset,
    required this.personAsset,
    required this.category,
    required this.renderTimeSec,
  });

  final String resultAsset;
  final String personAsset;
  final String category;
  final double renderTimeSec;
}

class DemoResults {
  DemoResults._(this._items);

  static const folder = 'assets/images/demo';
  static const indexAsset = '$folder/index.json';

  final Map<String, DemoResult> _items;

  static String key(String mannequinId, String garmentId) => '$mannequinId|$garmentId';

  int get length => _items.length;

  DemoResult? lookup(String? mannequinId, String? garmentId) {
    if (mannequinId == null || garmentId == null) return null;
    return _items[key(mannequinId, garmentId)];
  }

  /// index.json biçimi: {"items": [{"mannequin", "garment", "category", "result", "person", "render_time"}]}
  static DemoResults parse(String json) {
    final items = <String, DemoResult>{};
    final list = (jsonDecode(json) as Map<String, dynamic>)['items'] as List<dynamic>? ?? const [];
    for (final raw in list) {
      final m = raw as Map<String, dynamic>;
      items[key(m['mannequin'] as String, m['garment'] as String)] = DemoResult(
        resultAsset: '$folder/${m['result']}',
        personAsset: '$folder/${m['person']}',
        category: m['category'] as String? ?? 'upper',
        renderTimeSec: (m['render_time'] as num?)?.toDouble() ?? 0,
      );
    }
    return DemoResults._(items);
  }

  /// Dizin yoksa (sonuçlar henüz üretilmemişse) boş liste döner; demo düğmesi hiç görünmez.
  static Future<DemoResults> load(AssetBundle bundle) async {
    try {
      return parse(await bundle.loadString(indexAsset));
    } catch (_) {
      return DemoResults._(const {});
    }
  }
}

/// Yükleme ekranına hangi hazır manken ve kıyafetin seçildiğini taşır.
class DemoPair {
  const DemoPair(this.mannequinId, this.garmentId);

  final String mannequinId;
  final String garmentId;
}
