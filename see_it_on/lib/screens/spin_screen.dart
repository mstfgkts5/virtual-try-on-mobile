import 'dart:async';

import 'package:flutter/material.dart';

import '../core/design/widgets.dart';
import '../core/l10n_ext.dart';
import '../models/spin.dart';
import '../services/api_service.dart';
import '../widgets/spin_viewer.dart';

/// 360° dönüş: canlı iş (video → backend) ya da hazır set (paketlenmiş kareler).
class SpinScreen extends StatefulWidget {
  /// Backend'de dönüş işi başlatır, hazır olan kareleri geldikçe gösterir.
  const SpinScreen.live({
    super.key,
    required SpinRequest this.request,
    this.api,
    this.pollEvery = const Duration(seconds: 3),
  })  : presetFrames = null,
        title = null;

  /// Önceden üretilmiş kareleri hemen gösterir; backend çağrısı yok.
  const SpinScreen.preset({super.key, required List<ImageProvider> frames, required String this.title})
      : presetFrames = frames,
        request = null,
        api = null,
        pollEvery = const Duration(seconds: 3);

  final SpinRequest? request;
  final ApiService? api;
  final Duration pollEvery;
  final List<ImageProvider>? presetFrames;
  final String? title;

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
  static const _maxPollFailures = 3;

  late final ApiService _api = widget.api ?? ApiService();
  final _viewer = SpinViewerController();
  final _frames = <SpinFrame>[];
  final _images = <ImageProvider>[];
  Timer? _timer;
  String? _jobId;
  SpinState _state = SpinState.queued;
  int _total = 0;
  int _failures = 0;
  bool _busy = false;
  String? _error;

  bool get _isLive => widget.request != null;
  List<ImageProvider> get _shown => widget.presetFrames ?? _images;

  @override
  void initState() {
    super.initState();
    if (_isLive) _start();
  }

  Future<void> _start() async {
    try {
      final id = await _api.startSpin(widget.request!);
      if (!mounted) {
        _api.cancelSpin(id);
        return;
      }
      setState(() {
        _jobId = id;
        _total = widget.request!.frames;
      });
      _timer = Timer.periodic(widget.pollEvery, (_) => _poll());
    } catch (e) {
      if (mounted) setState(() => _error = ApiService.friendlyError(context.l10n, e));
    }
  }

  Future<void> _poll() async {
    if (_busy || _jobId == null) return;
    _busy = true;
    try {
      final s = await _api.spinStatus(_jobId!, since: _frames.length);
      if (!mounted) return;
      setState(() {
        _failures = 0;
        _state = s.state;
        _total = s.total;
        for (final f in s.frames) {
          if (f.index == _frames.length) {
            _frames.add(f);
            _images.add(MemoryImage(f.bytes));
          }
        }
        if (s.state == SpinState.failed) _error = s.error ?? '';
        if (s.state == SpinState.cancelled) _error = context.l10n.spinCancelled;
      });
      if (s.isFinished) _timer?.cancel();
    } catch (e) {
      // Tek seferlik ağ kopması işi bozmasın; art arda birkaç hata olursa vazgeç
      _failures++;
      if (_failures >= _maxPollFailures && mounted) {
        _timer?.cancel();
        setState(() => _error = ApiService.friendlyError(context.l10n, e));
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    final finished = _state == SpinState.done || _state == SpinState.failed || _state == SpinState.cancelled;
    if (_jobId != null && !finished) _api.cancelSpin(_jobId!);
    _viewer.dispose();
    super.dispose();
  }

  int? get _etaMinutes {
    // Süreyi yalnızca giydirilmiş ana kareler belirler; ara kareler neredeyse anlık
    final keys = _frames.where((f) => !f.isTween).toList();
    final remaining = _total - _frames.length;
    if (keys.isEmpty || remaining <= 0) return null;
    final avg = keys.map((f) => f.renderTimeSec).reduce((a, b) => a + b) / keys.length;
    final requested = widget.request?.frames ?? keys.length;
    final remainingKeys = (requested - keys.length).clamp(0, requested);
    return (avg * remainingKeys / 60).ceil().clamp(1, 99);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final frames = _shown;
    final running = _isLive && _error == null && _state != SpinState.done;

    return Scaffold(
      backgroundColor: t.paper,
      appBar: AppBar(title: Text(widget.title ?? l.spinTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(SeeItOnTokens.radiusLg),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line)),
                        child: frames.isEmpty
                            ? Center(
                                child: _error == null
                                    ? CircularProgressIndicator(strokeWidth: 1.5, color: t.accent)
                                    : Icon(Icons.error_outline, color: t.danger),
                              )
                            : SpinViewer(frames: frames, controller: _viewer),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Text(
                      l.spinFailed(_error!),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: t.danger),
                    )
                  else if (running) ...[
                    Text(
                      _jobId == null ? l.spinStarting : l.spinProgress(_frames.length, _total),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _total == 0 ? null : _frames.length / _total,
                      minHeight: 2,
                      color: t.accent,
                      backgroundColor: t.line,
                    ),
                    if (_etaMinutes != null) ...[
                      const SizedBox(height: 6),
                      Caption(l.spinEta(_etaMinutes!)),
                    ],
                  ],
                  if (frames.length > 1) ...[
                    const SizedBox(height: 10),
                    Caption(l.spinDragHint, italic: true),
                  ],
                  const SizedBox(height: 14),
                  ListenableBuilder(
                    listenable: _viewer,
                    builder: (context, _) => PillButton(
                      label: _viewer.isPlaying ? l.spinStop : l.spinPlay,
                      icon: _viewer.isPlaying ? Icons.pause : Icons.threesixty,
                      expand: true,
                      onPressed: frames.length > 1 ? () => _viewer.isPlaying ? _viewer.stop() : _viewer.play() : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
