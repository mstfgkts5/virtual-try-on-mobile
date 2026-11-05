import 'package:image_picker/image_picker.dart';

/// Galeri/kamera seçici; testlerde sahte seçici verilir.
abstract class MediaPicker {
  Future<XFile?> pickImage(ImageSource source);
  Future<XFile?> pickVideo(ImageSource source);
}

class ImagePickerMediaPicker implements MediaPicker {
  ImagePickerMediaPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickImage(ImageSource source) => _picker.pickImage(source: source);

  // Dönüş videosu en fazla 30 sn olabilir (backend sınırı)
  @override
  Future<XFile?> pickVideo(ImageSource source) =>
      _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 30));
}
