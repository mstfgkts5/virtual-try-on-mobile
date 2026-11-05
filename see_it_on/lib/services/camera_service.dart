import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Kullanıcı kamera iznini vermedi (veya sistem kısıtladı).
class CameraAccessDeniedException implements Exception {
  const CameraAccessDeniedException();
}

/// Cihazda kullanılabilir kamera yok.
class NoCameraException implements Exception {
  const NoCameraException();
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

  @override
  bool get hasMultipleCameras => _cameras.length > 1;

  @override
  Future<void> init({bool front = true}) async {
    _front = front;
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) throw const NoCameraException();
      final wanted = front ? CameraLensDirection.front : CameraLensDirection.back;
      final camera = _cameras.firstWhere((c) => c.lensDirection == wanted, orElse: () => _cameras.first);
      await _controller?.dispose();
      final controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
      _controller = controller;
      await controller.initialize();
    } on CameraException catch (e) {
      throw _translate(e);
    }
  }

  static Exception _translate(CameraException e) {
    final code = e.code.toLowerCase();
    if (code.contains('denied') || code.contains('permission') || code.contains('restricted')) {
      return const CameraAccessDeniedException();
    }
    if (code.contains('notfound') || code.contains('nocamera') || code.contains('notreadable')) {
      return const NoCameraException();
    }
    return e;
  }

  @override
  Widget preview() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const SizedBox.shrink();
    // Önizleme kutuyu kaplar (kenarlar kırpılır); dikey ekranda yükseklik/genişlik = aspectRatio
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: 1, height: c.value.aspectRatio, child: CameraPreview(c)),
      ),
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
    final c = _controller;
    _controller = null;
    await c?.dispose();
  }
}
