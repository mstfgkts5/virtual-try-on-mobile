import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/design/theme.dart';
import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';
import '../models/tryon_request.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import 'loading_screen.dart';

/// Canlı denemede yan şeritte duran kıyafet.
class LiveGarment {
  const LiveGarment({required this.id, required this.name, required this.category, required this.bytes});

  final String id;
  final String name;
  final String category; // 'upper' | 'lower' | 'overall'
  final Uint8List bytes;
}

/// "Neredeyse canlı" deneme: kamera açık kalır, şeritten seçilen kıyafet birkaç saniyede bir
/// o anki kare üzerine (önizleme kalitesinde, ~2 sn) giydirilip kameranın üstünde gösterilir.
/// Aynı anda tek istek gönderilir; sonuç gelince yeni kare çekilir.
class LiveTryOnScreen extends StatefulWidget {
  const LiveTryOnScreen({
    super.key,
    required this.garments,
    this.camera,
    this.api,
    this.pause = const Duration(milliseconds: 300),
  });

  final List<LiveGarment> garments;
  final CameraService? camera;
  final ApiService? api;

  /// İki önizleme isteği arasındaki kısa bekleme
  final Duration pause;

  @override
  State<LiveTryOnScreen> createState() => _LiveTryOnScreenState();
}

class _LiveTryOnScreenState extends State<LiveTryOnScreen> with WidgetsBindingObserver {
  static const _maxFailures = 3;

  late final CameraService _camera = widget.camera ?? PluginCameraService();
  late final ApiService _api = widget.api ?? ApiService();
  bool _ready = false;
  String? _cameraError;
  LiveGarment? _selected;
  Uint8List? _result;
  Uint8List? _lastFrame;
  bool _busy = false;
  int _failures = 0;
  String? _error;
  int _loopToken = 0; // her seçim/durdurma yeni bir döngü başlatır; eskisi kendiliğinden biter

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loopToken++;
    _camera.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _loopToken++;
      _camera.dispose();
      if (mounted) setState(() => _ready = false);
    } else if (state == AppLifecycleState.resumed && !_ready) {
      _startCamera().then((_) {
        if (_selected != null) _loop();
      });
    }
  }

  Future<void> _startCamera() async {
    try {
      await _camera.init();
      if (mounted) setState(() => _ready = true);
    } on CameraAccessDeniedException {
      if (mounted) setState(() => _cameraError = context.l10n.cameraDenied);
    } catch (e) {
      if (mounted) setState(() => _cameraError = context.l10n.cameraUnavailable);
    }
  }

  void _toggle(LiveGarment g) {
    setState(() {
      if (_selected?.id == g.id) {
        _selected = null; // aynı kıyafete tekrar dokunmak durdurur
        _result = null;
      } else {
        _selected = g;
        _result = null;
      }
      _failures = 0;
      _error = null;
    });
    _loop();
  }

  Future<void> _loop() async {
    final token = ++_loopToken;
    while (mounted && token == _loopToken && _selected != null && _ready) {
      final garment = _selected!;
      setState(() => _busy = true);
      try {
        final frame = await _camera.capture();
        if (!mounted || token != _loopToken) break;
        final res = await _api.processVirtualTryOn(TryOnRequest(
          personImageBytes: frame,
          garmentImageBytes: garment.bytes,
          category: garment.category,
          preview: true,
        ));
        if (!mounted || token != _loopToken) break;
        setState(() {
          _lastFrame = frame;
          _result = res.resultImageBytes;
          _failures = 0;
          _error = null;
        });
      } catch (e) {
        if (!mounted || token != _loopToken) break;
        _failures++;
        if (_failures >= _maxFailures) {
          setState(() {
            _error = context.l10n.liveFailed(ApiService.friendlyError(context.l10n, e));
            _busy = false;
          });
          return; // art arda hata: döngü durur, kullanıcı kıyafete tekrar dokunarak yeniden dener
        }
      }
      await Future<void>.delayed(widget.pause);
    }
    if (mounted && token == _loopToken) setState(() => _busy = false);
  }

  void _save() {
    final frame = _lastFrame, garment = _selected;
    if (frame == null || garment == null) return;
    _loopToken++; // tam kalite sırasında GPU önizlemeyle paylaşılmasın
    setState(() => _busy = false);
    pushEditorial(
      context,
      LoadingScreen(personImageBytes: frame, garmentImageBytes: garment.bytes, category: garment.category),
    ).then((_) {
      if (mounted && _selected != null) _loop();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kamera ekranı her zaman koyu (fotoğraf karanlık zeminde daha iyi okunur)
    return Theme(data: buildTheme(Brightness.dark), child: Builder(builder: _buildBody));
  }

  Widget _buildBody(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: t.paper,
      appBar: AppBar(title: Text(l.liveTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(SeeItOnTokens.radiusLg),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const ColoredBox(color: Colors.black),
                            if (_cameraError != null)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(_cameraError!, textAlign: TextAlign.center, style: text.bodyMedium),
                                ),
                              )
                            else if (_ready)
                              _camera.preview()
                            else
                              Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: t.accent)),
                            if (_result != null && _selected != null)
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                child: Transform(
                                  key: ValueKey(_result.hashCode),
                                  alignment: Alignment.center,
                                  // Ön kamera önizlemesi aynalı; giydirilmiş kare de aynı yöne çevrilir
                                  transform: Matrix4.diagonal3Values(_camera.isFront ? -1 : 1, 1, 1),
                                  child: Image.memory(
                                    _result!,
                                    key: const ValueKey('live-result'),
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 12,
                              left: 12,
                              right: 12,
                              child: _StatusChip(
                                text: _error ??
                                    (_selected == null ? l.liveHint : (_busy ? l.liveUpdating : _selected!.name)),
                                error: _error != null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 72,
                      child: ListView(
                        children: [
                          for (final g in widget.garments)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GestureDetector(
                                key: ValueKey('live-garment-${g.id}'),
                                onTap: () => _toggle(g),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 96,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: t.surface,
                                    borderRadius: BorderRadius.circular(SeeItOnTokens.radiusSm),
                                    border: Border.all(
                                      color: _selected?.id == g.id ? t.accent : t.line,
                                      width: _selected?.id == g.id ? 2.5 : 1,
                                    ),
                                  ),
                                  child: Image.memory(g.bytes, fit: BoxFit.cover, semanticLabel: g.name),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: PillButton(
                label: l.liveSave,
                icon: Icons.check,
                expand: true,
                onPressed: _result != null && _lastFrame != null ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (error ? t.danger : Colors.black).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(SeeItOnTokens.radiusPill),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
