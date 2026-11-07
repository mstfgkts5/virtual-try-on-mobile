import 'dart:convert';
import 'dart:typed_data';

/// 360° dönüşün giydirilmiş tek karesi.
class SpinFrame {
  const SpinFrame({
    required this.index,
    required this.view,
    required this.bytes,
    this.renderTimeSec = 0,
    this.kind = 'key',
  });

  final int index;
  final String view; // 'front' | 'back'
  final Uint8List bytes;
  final double renderTimeSec;
  final String kind; // 'key' (giydirilmiş) | 'tween' (RIFE ara kare)

  bool get isBack => view == 'back';
  bool get isTween => kind == 'tween';

  factory SpinFrame.fromJson(Map<String, dynamic> json) => SpinFrame(
        index: json['index'] as int,
        view: json['view'] as String? ?? 'front',
        bytes: base64Decode(json['image_base64'] as String),
        renderTimeSec: (json['render_time'] as num?)?.toDouble() ?? 0,
        kind: json['kind'] as String? ?? 'key',
      );
}

enum SpinState { queued, running, done, failed, cancelled }

/// Backend'deki dönüş işinin durumu (`GET /api/v1/spin/{id}`).
class SpinStatus {
  const SpinStatus({required this.state, required this.total, required this.done, required this.frames, this.error});

  final SpinState state;
  final int total;
  final int done;
  final List<SpinFrame> frames; // `since` sonrası yeni kareler
  final String? error;

  bool get isFinished => state == SpinState.done || state == SpinState.failed || state == SpinState.cancelled;

  factory SpinStatus.fromJson(Map<String, dynamic> json) => SpinStatus(
        state: SpinState.values.firstWhere((s) => s.name == json['status'], orElse: () => SpinState.failed),
        total: json['total'] as int? ?? 0,
        done: json['done'] as int? ?? 0,
        frames: [for (final f in (json['frames'] as List? ?? const [])) SpinFrame.fromJson(f as Map<String, dynamic>)],
        error: json['error'] as String?,
      );
}

/// Dönüş işi isteği: video + kıyafetin önü (+ isteğe bağlı arkası).
class SpinRequest {
  const SpinRequest({
    required this.videoBytes,
    required this.videoName,
    required this.garmentFront,
    this.garmentBack,
    this.category = 'upper',
    this.frames = 12, // ana kare; backend aralarına RIFE ara kareleri ekler
  });

  final Uint8List videoBytes;
  final String videoName;
  final Uint8List garmentFront;
  final Uint8List? garmentBack;
  final String category;
  final int frames;
}
