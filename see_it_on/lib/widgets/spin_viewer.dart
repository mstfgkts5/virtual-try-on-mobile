import 'package:flutter/material.dart';

/// [SpinViewer]'ın konumunu dışarıdan okumak ve "Döndür" ile oynatmak için.
/// `position` 0 ile kare sayısı arasında süreklidir; 2,5 = 2. ve 3. karenin yarı yarıya karışımı.
class SpinViewerController extends ChangeNotifier {
  double _position = 0;
  int _count = 0;
  bool _playing = false;
  VoidCallback? _start;
  VoidCallback? _stop;

  double get position => _position;
  bool get isPlaying => _playing;

  /// Tam turu baştan sona bir kez oynatır (tek karede bir şey yapmaz).
  void play() {
    if (_count < 2) return;
    _start?.call();
  }

  void stop() => _stop?.call();

  void _set(double value) {
    if (_count == 0) {
      _position = 0;
    } else {
      _position = value % _count;
      if (_position < 0) _position += _count;
    }
    notifyListeners();
  }

  void _setPlaying(bool value) {
    _playing = value;
    notifyListeners();
  }
}

/// Dönüş kareleri: parmakla sağa sola sürükledikçe kişi kendi etrafında döner.
/// Genişliğin tamamı kadar sürükleme = tam tur; komşu kareler arasında saydamlıkla geçiş yapılır.
class SpinViewer extends StatefulWidget {
  const SpinViewer({super.key, required this.frames, this.controller});

  final List<ImageProvider> frames;
  final SpinViewerController? controller;

  @override
  State<SpinViewer> createState() => _SpinViewerState();
}

class _SpinViewerState extends State<SpinViewer> with SingleTickerProviderStateMixin {
  static const _turnDuration = Duration(seconds: 4);

  late SpinViewerController _controller = widget.controller ?? SpinViewerController();
  late final AnimationController _anim = AnimationController(vsync: this, duration: _turnDuration);
  double _playFrom = 0;

  @override
  void initState() {
    super.initState();
    _attach();
    _anim.addListener(() => _controller._set(_playFrom + _anim.value * widget.frames.length));
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller._set(_playFrom);
        _controller._setPlaying(false);
      }
    });
  }

  void _attach() {
    _controller
      .._count = widget.frames.length
      .._start = _play
      .._stop = _stopPlaying;
  }

  void _play() {
    _playFrom = _controller.position;
    _controller._setPlaying(true);
    _anim.forward(from: 0);
  }

  void _stopPlaying() {
    if (!_anim.isAnimating) return;
    _anim.stop();
    _controller._setPlaying(false);
  }

  @override
  void didUpdateWidget(SpinViewer old) {
    super.didUpdateWidget(old);
    if (widget.controller != null && widget.controller != _controller) _controller = widget.controller!;
    // Yeni kareler gelince konum korunur
    _attach();
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller
      .._start = null
      .._stop = null;
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onDrag(DragUpdateDetails d, double width) {
    final n = widget.frames.length;
    if (n < 2 || width <= 0) return;
    _stopPlaying();
    // Sola sürükleme saat yönünde ilerletir
    _controller._set(_controller.position - d.delta.dx / width * n);
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.frames;
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) => _onDrag(d, constraints.maxWidth),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (frames.isEmpty) return const SizedBox.expand();
            final p = _controller.position;
            final a = p.floor() % frames.length;
            final b = (a + 1) % frames.length;
            final t = p - p.floor();
            return Stack(
              fit: StackFit.expand,
              children: [
                Image(image: frames[a], fit: BoxFit.cover, gaplessPlayback: true),
                if (frames.length > 1 && t > 0.001)
                  Opacity(opacity: t, child: Image(image: frames[b], fit: BoxFit.cover, gaplessPlayback: true)),
              ],
            );
          },
        ),
      ),
    );
  }
}
