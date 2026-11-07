import 'dart:typed_data';

class TryOnRequest {
  final Uint8List personImageBytes;
  final String? personImageName;
  final Uint8List garmentImageBytes;
  final String? garmentImageName;
  final String category; // 'upper', 'lower', 'overall'

  TryOnRequest({
    required this.personImageBytes,
    this.personImageName,
    required this.garmentImageBytes,
    this.garmentImageName,
    this.category = 'upper', // Varsayılan üst giyim
  });

  Map<String, String> toFieldsMap() {
    return {
      'category': category.toLowerCase(),
      'steps': '15', // 15 adım · 576x768: tek görsel ~17 sn (30 adım · 768x1024: ~74 sn)
    };
  }
}
