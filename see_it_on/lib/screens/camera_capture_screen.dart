import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/design/theme.dart';
import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';
import '../services/camera_service.dart';

/// Kamera ekranından galeri seçimine geçildiğini bildirir (`Navigator.pop<Object>(CameraResult.gallery)`).
enum CameraResult { gallery }

/// Önizlemenin üstüne çizilen katman. Bugün sabit silüet rehberi; 2. aşamada (canlı AR)
/// poz algılamadan beslenen bir `PoseOverlay` aynı yuvaya takılır.
abstract class CameraOverlay {
  const CameraOverlay();
  Widget build(BuildContext context);
}

/// İnce accent çizgili tam boy silüet + çekim ipucu.
class SilhouetteOverlay extends CameraOverlay {
  const SilhouetteOverlay();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
          child: CustomPaint(painter: _SilhouettePainter(t.accent)),
        ),
        Positioned(
          top: 14,
          left: 16,
          right: 16,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(SeeItOnTokens.radiusPill),
              ),
              child: Text(
                context.l10n.cameraHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kafa, omuzlar, hafif açık kollar ve bacaklardan oluşan rehber çizgisi.
class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Kutunun içinde 1:2.6 oranlı bir gövde alanı
    final h = size.height;
    final w = (h / 2.6).clamp(0.0, size.width);
    final cx = size.width / 2;
    Offset p(double x, double y) => Offset(cx + x * w, y * h);

    canvas.drawOval(Rect.fromCenter(center: p(0, 0.075), width: w * 0.26, height: h * 0.11), paint);
    final body = Path()
      ..moveTo(p(-0.06, 0.13).dx, p(-0.06, 0.13).dy)
      ..lineTo(p(-0.06, 0.155).dx, p(-0.06, 0.155).dy)
      // sol omuz ve kol (hafif açık)
      ..quadraticBezierTo(p(-0.34, 0.165).dx, p(-0.34, 0.165).dy, p(-0.36, 0.24).dx, p(-0.36, 0.24).dy)
      ..lineTo(p(-0.50, 0.50).dx, p(-0.50, 0.50).dy)
      ..lineTo(p(-0.42, 0.52).dx, p(-0.42, 0.52).dy)
      ..lineTo(p(-0.26, 0.30).dx, p(-0.26, 0.30).dy)
      // sol bel, bacak
      ..lineTo(p(-0.22, 0.52).dx, p(-0.22, 0.52).dy)
      ..lineTo(p(-0.20, 0.98).dx, p(-0.20, 0.98).dy)
      ..lineTo(p(-0.05, 0.98).dx, p(-0.05, 0.98).dy)
      ..lineTo(p(0, 0.58).dx, p(0, 0.58).dy)
      // sağ bacak, bel
      ..lineTo(p(0.05, 0.98).dx, p(0.05, 0.98).dy)
      ..lineTo(p(0.20, 0.98).dx, p(0.20, 0.98).dy)
      ..lineTo(p(0.22, 0.52).dx, p(0.22, 0.52).dy)
      ..lineTo(p(0.26, 0.30).dx, p(0.26, 0.30).dy)
      // sağ kol ve omuz
      ..lineTo(p(0.42, 0.52).dx, p(0.42, 0.52).dy)
      ..lineTo(p(0.50, 0.50).dx, p(0.50, 0.50).dy)
      ..lineTo(p(0.36, 0.24).dx, p(0.36, 0.24).dy)
      ..quadraticBezierTo(p(0.34, 0.165).dx, p(0.34, 0.165).dy, p(0.06, 0.155).dx, p(0.06, 0.155).dy)
      ..lineTo(p(0.06, 0.13).dx, p(0.06, 0.13).dy);
    canvas.drawPath(body, paint);
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) => old.color != color;
}

enum _Phase { starting, ready, countdown, review, denied, unavailable }

/// Uygulama içi tam boy fotoğraf çekimi. Sonuç: `Uint8List` (kullanılan fotoğraf),
/// [CameraResult.gallery] (galeriye geçiş) veya `null` (vazgeçildi).
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({
    super.key,
    this.service,
    this.overlay = const SilhouetteOverlay(),
    this.countdown = const Duration(seconds: 3),
  });

  /// Verilmezse gerçek kamera kullanılır; testlerde sahte servis verilir.
  final CameraService? service;
  final CameraOverlay overlay;
  final Duration countdown;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> with WidgetsBindingObserver {
  late final CameraService _camera = widget.service ?? PluginCameraService();
  _Phase _phase = _Phase.starting;
  int _remaining = 0;
  Timer? _timer;
  Uint8List? _shot;
  bool _released = false;
  bool _switching = false;

  /// Her başlatma ve bırakmada artar; geç gelen eski başlatma sonuçları yok sayılır.
  int _startToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _release();
    super.dispose();
  }

  void _release() {
    _startToken++;
    if (_released) return;
    _released = true;
    _camera.dispose();
  }

  // Uygulama arka plana geçince kamera bırakılır, dönünce yeniden açılır
  // (çekilen fotoğrafın önizlemesindeyken de: "Tekrar çek" canlı kamerayla devam eder)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _release();
      if (_phase == _Phase.countdown) setState(() => _phase = _Phase.ready);
    } else if (state == AppLifecycleState.resumed && _released) {
      _start();
    }
  }

  Future<void> _start() async {
    final token = ++_startToken;
    _released = false;
    _Phase next;
    try {
      await _camera.init();
      next = _Phase.ready;
    } on CameraAccessDeniedException {
      next = _Phase.denied;
    } catch (e) {
      debugPrint('[CameraCapture] Kamera açılamadı: $e');
      next = _Phase.unavailable;
    }
    if (!mounted || token != _startToken) return;
    // Önizlemedeki fotoğraf, kamera arka planda yeniden açıldı diye kaybolmaz
    if (next == _Phase.ready && _phase == _Phase.review) return;
    setState(() => _phase = next);
  }

  void _onShutter() {
    final seconds = widget.countdown.inSeconds;
    if (seconds <= 0) {
      _capture();
      return;
    }
    setState(() {
      _phase = _Phase.countdown;
      _remaining = seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_remaining <= 1) {
        timer.cancel();
        _capture();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _capture() async {
    try {
      final bytes = await _camera.capture();
      if (mounted) {
        setState(() {
          _shot = bytes;
          _phase = _Phase.review;
        });
      }
    } catch (e) {
      debugPrint('[CameraCapture] Çekim hatası: $e');
      if (mounted) setState(() => _phase = _Phase.ready);
    }
  }

  void _retake() {
    setState(() {
      _shot = null;
      _phase = _released ? _Phase.starting : _Phase.ready;
    });
    if (_released) _start();
  }

  void _use() {
    _release();
    Navigator.pop<Object>(context, _shot);
  }

  void _gallery() {
    _release();
    Navigator.pop<Object>(context, CameraResult.gallery);
  }

  Future<void> _switch() async {
    if (_switching) return;
    setState(() => _switching = true);
    try {
      await _camera.switchCamera();
    } catch (e) {
      debugPrint('[CameraCapture] Kamera değiştirilemedi: $e');
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kamera ekranı her zaman koyu: fotoğraf ve vizör karanlık zeminde daha iyi okunur
    return Theme(
      data: buildTheme(Brightness.dark),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final failed = _phase == _Phase.denied || _phase == _Phase.unavailable;

    return Scaffold(
      backgroundColor: t.paper,
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.cameraClose,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('SeeItOn'),
        actions: [
          if (_phase == _Phase.ready && !_switching && _camera.hasMultipleCameras)
            IconButton(tooltip: l.cameraSwitch, icon: const Icon(Icons.cameraswitch_outlined), onPressed: _switch),
        ],
      ),
      body: SafeArea(
        top: false,
        child: failed ? _buildFailure(context) : _buildViewfinder(context),
      ),
    );
  }

  Widget _buildFailure(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_phase == _Phase.denied ? Icons.no_photography_outlined : Icons.videocam_off_outlined, color: t.muted, size: 36),
            const SizedBox(height: 18),
            EditorialHeading(_phase == _Phase.denied ? l.cameraDenied : l.cameraUnavailable, size: 22, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            PillButton(label: l.cameraUseGallery, icon: Icons.photo_library_outlined, onPressed: _gallery),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinder(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final reviewing = _phase == _Phase.review && _shot != null;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(SeeItOnTokens.radiusLg),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Colors.black),
                      if (reviewing)
                        Image.memory(_shot!, fit: BoxFit.cover)
                      else if (_phase != _Phase.starting) ...[
                        _camera.preview(),
                        widget.overlay.build(context),
                      ] else
                        Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: t.accent)),
                      if (_phase == _Phase.countdown)
                        Center(
                          child: Text(
                            '$_remaining',
                            style: Theme.of(context).textTheme.displaySmall!.copyWith(fontSize: 96, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: reviewing
              ? Row(
                  children: [
                    Expanded(child: PillButton(label: l.cameraRetake, icon: Icons.refresh, primary: false, expand: true, onPressed: _retake)),
                    const SizedBox(width: 12),
                    Expanded(child: PillButton(label: l.cameraUse, icon: Icons.check, expand: true, onPressed: _use)),
                  ],
                )
              : SizedBox(
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: l.cameraUseGallery,
                          icon: Icon(Icons.photo_library_outlined, color: t.ink),
                          onPressed: _gallery,
                        ),
                      ),
                      _Shutter(onTap: _phase == _Phase.ready && !_switching ? _onShutter : null, label: l.cameraCapture),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.onTap, required this.label});

  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        key: const ValueKey('camera-shutter'),
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.ink, width: 2)),
            child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: t.ink)),
          ),
        ),
      ),
    );
  }
}
