import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kullanıcı kamera iznini vermedi (veya sistem kısıtladı).
class CameraAccessDeniedException implements Exception {
  const CameraAccessDeniedException();
}

/// Cihazda kullanılabilir kamera yok.
class NoCameraException implements Exception {
  const NoCameraException();
}

/// Kamera eklentisinin hata kodunu uygulamanın hatalarına çevirir; tanınmayan kodlar için `null`.
/// Kodlar: Android/iOS `CameraAccessDenied*`, `CameraAccessRestricted`; web `cameraPermission`, `cameraNotFound`.
/// `CameraPermissionsRequestOngoing` bilerek eşleşmez: izin penceresi hâlâ açıktır, reddedilmemiştir.
Exception? classifyCameraError(String code) {
  const denied = {
    'CameraAccessDenied',
    'CameraAccessDeniedWithoutPrompt',
    'CameraAccessRestricted',
    'cameraPermission',
  };
  const missing = {'cameraNotFound', 'noCamerasAvailable'};
  if (denied.contains(code)) return const CameraAccessDeniedException();
  if (missing.contains(code)) return const NoCameraException();
  return null;
}

/// Uygulama içi kamera. Ekran bu arayüze bağlıdır; testlerde sahte servis verilir.
///
/// İleride canlı AR (2. aşama) için aynı servise kare akışı (`startImageStream`) eklenip
/// bir `FrameAnalyzer`'a (ör. ML Kit poz algılama) bağlanacak; ekranın değişmesi gerekmez.
abstract class CameraService {
  Future<void> init({bool front = true});
  Widget preview();
  Future<Uint8List> capture();
  Future<void> switchCamera();
  Future<void> dispose();
  bool get hasMultipleCameras;
}

/// `camera` eklentisiyle gerçek kamera.
class PluginCameraService implements CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  bool _front = true;

  /// Her init ve dispose artırır; bekleme sırasında geçersiz kalmış bir init,
  /// açtığı kamerayı kendisi kapatır (ör. izin penceresi açıkken ekran kapatıldı).
  int _generation = 0;

  @override
  bool get hasMultipleCameras => _cameras.length > 1;

  @override
  Future<void> init({bool front = true}) async {
    final generation = ++_generation;
    _front = front;
    // Önceki kamera, yenisi açılmadan önce bırakılır (Android aynı anda iki kamerayı açamayabilir)
    final old = _controller;
    _controller = null;
    try {
      await old?.dispose();
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (generation != _generation) return;
      if (_cameras.isEmpty) throw const NoCameraException();
      final wanted = front ? CameraLensDirection.front : CameraLensDirection.back;
      final camera = _cameras.firstWhere((c) => c.lensDirection == wanted, orElse: () => _cameras.first);
      final controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
      try {
        await controller.initialize();
      } catch (_) {
        await controller.dispose();
        rethrow;
      }
      if (generation != _generation) {
        await controller.dispose();
        return;
      }
      _controller = controller;
    } on CameraException catch (e) {
      throw classifyCameraError(e.code) ?? e;
    }
  }

  @override
  Widget preview() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const SizedBox.shrink();
    // CameraPreview yatay yönde (masaüstü web kamerası, yan çevrilmiş telefon) yatay oranla,
    // dikeyde ters oranla çizilir; kutu aynı yönde kurulur ki önizleme 3:4 alanı kaplasın
    return ValueListenableBuilder<CameraValue>(
      valueListenable: c,
      builder: (context, value, _) {
        final orientation = value.previewPauseOrientation ?? value.lockedCaptureOrientation ?? value.deviceOrientation;
        final landscape = orientation == DeviceOrientation.landscapeLeft || orientation == DeviceOrientation.landscapeRight;
        final ratio = value.aspectRatio;
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: landscape ? ratio : 1,
              height: landscape ? 1 : ratio,
              child: CameraPreview(c),
            ),
          ),
        );
      },
    );
  }

  @override
  Future<Uint8List> capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) throw const NoCameraException();
    final file = await c.takePicture();
    return file.readAsBytes();
  }

  @override
  Future<void> switchCamera() => init(front: !_front);

  @override
  Future<void> dispose() async {
    _generation++;
    final c = _controller;
    _controller = null;
    await c?.dispose();
  }
}
