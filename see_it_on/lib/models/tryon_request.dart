import 'dart:typed_data';

class TryOnRequest {
  final Uint8List personImageBytes;
  final String? personImageName;
  final Uint8List garmentImageBytes;
  final String? garmentImageName;
  final String category; // 'upper_body', 'lower_body', 'dresses'
  final String fitType; // 'Tailored', 'Regular', 'Oversized'
  final bool lockPose;
  final bool autoCleanBg;

  TryOnRequest({
    required this.personImageBytes,
    this.personImageName,
    required this.garmentImageBytes,
    this.garmentImageName,
    this.category = 'upper_body', // Varsayılan üst giyim
    this.fitType = 'Tailored',
    this.lockPose = false,
    this.autoCleanBg = true,
  });

  Map<String, String> toFieldsMap() {
    return {
      'category': category.toLowerCase(), // KESİN ÇÖZÜM: Artık kategori FastAPI'ye gidiyor!
      'fit_type': fitType.toLowerCase(),
      'lock_pose': lockPose.toString(),
      'auto_clean_bg': autoCleanBg.toString(),
      'model_version': 'idm-vton-3.2',
    };
  }
}