import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/models/spin.dart';

void main() {
  final png = base64Encode([137, 80, 78, 71, 1, 2, 3]);

  test('SpinStatus JSON çözülür', () {
    final s = SpinStatus.fromJson({
      'status': 'running',
      'total': 8,
      'done': 2,
      'error': null,
      'frames': [
        {'index': 0, 'view': 'front', 'image_base64': png, 'render_time': 41.2},
        {'index': 1, 'view': 'back', 'kind': 'tween', 'image_base64': png, 'render_time': 0},
      ],
    });
    expect(s.state, SpinState.running);
    expect(s.total, 8);
    expect(s.done, 2);
    expect(s.frames, hasLength(2));
    expect(s.frames[1].isBack, isTrue);
    expect(s.frames[1].isTween, isTrue);
    expect(s.frames[0].isTween, isFalse); // 'kind' yoksa ana kare sayılır
    expect(s.frames[0].isBack, isFalse);
    expect(s.frames[0].bytes.sublist(0, 4), [137, 80, 78, 71]);
    expect(s.frames[0].renderTimeSec, 41.2);
    expect(s.isFinished, isFalse);
  });

  test('bilinmeyen durum başarısız sayılır', () {
    expect(SpinStatus.fromJson({'status': 'weird', 'total': 1, 'done': 0, 'frames': []}).state, SpinState.failed);
  });

  test('bitmiş durumlar', () {
    for (final name in ['done', 'failed', 'cancelled']) {
      expect(SpinStatus.fromJson({'status': name, 'total': 1, 'done': 1, 'frames': []}).isFinished, isTrue);
    }
    expect(SpinStatus.fromJson({'status': 'queued', 'total': 1, 'done': 0, 'frames': []}).isFinished, isFalse);
  });

  test('SpinRequest varsayılan 12 ana kare', () {
    final r = SpinRequest(videoBytes: Uint8List(1), videoName: 'v.mov', garmentFront: Uint8List(1), category: 'upper');
    expect(r.frames, 12);
    expect(r.garmentBack, isNull);
  });
}
