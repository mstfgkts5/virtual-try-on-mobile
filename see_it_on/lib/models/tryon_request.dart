import 'dart:typed_data';

class TryOnRequest {
  final Uint8List personImageBytes;
  final String? personImageName;
  final Uint8List garmentImageBytes;
  final String? garmentImageName;
  final String category; // 'upper', 'lower', 'overall'
  final String fitType; // 'Tailored', 'Regular', 'Oversized'
  final bool lockPose;
  final bool autoCleanBg;

  TryOnRequest({
    required this.personImageBytes,
    this.personImageName,
    required this.garmentImageBytes,
    this.garmentImageName,
    this.category = 'upper', // Varsayılan üst giyim
    this.fitType = 'Tailored',
    this.lockPose = false,
    this.autoCleanBg = true,
  });

  Map<String, String> toFieldsMap() {
    return {
      'category': category.toLowerCase(),
      'steps': '30',
    };
  }
}