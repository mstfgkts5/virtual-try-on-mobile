import 'dart:typed_data';

class TryOnRequest {
  final Uint8List personImageBytes;
  final String? personImageName;
  final Uint8List garmentImageBytes;
  final String? garmentImageName;
  final String category; // 'upper', 'lower', 'overall'
  /// Canlı deneme önizlemesi: backend 10 adım · 384x512 ile ~2 sn'de döner
  final bool preview;

  TryOnRequest({
    required this.personImageBytes,
    this.personImageName,
    required this.garmentImageBytes,
    this.garmentImageName,
    this.category = 'upper', // Varsayılan üst giyim
    this.preview = false,
  });

  Map<String, String> toFieldsMap() {
    return {
      'category': category.toLowerCase(),
      'steps': '8', // DPM++ 8 adım · 576x768: tek görsel ~4–9 sn (eski DDIM 30 adım · 768x1024: ~74 sn)
      if (preview) 'preview': 'true',
    };
  }
}
