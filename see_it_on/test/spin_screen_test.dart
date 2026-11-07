import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/models/spin.dart';
import 'package:see_it_on/screens/spin_screen.dart';
import 'package:see_it_on/services/api_service.dart';
import 'package:see_it_on/widgets/spin_viewer.dart';

import 'helpers.dart';

// 1x1 şeffaf PNG
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

SpinStatus status(String state, int done, {int total = 8, int from = 0, String? error}) => SpinStatus.fromJson({
      'status': state,
      'total': total,
      'done': done,
      'error': error,
      'frames': [
        for (var i = from; i < done; i++)
          {'index': i, 'view': 'front', 'image_base64': base64Encode(_png), 'render_time': 40.0},
      ],
    });

/// Sırayla verilen yanıtları döner (SpinStatus ya da istisna); son yanıt tekrar edilir.
class FakeSpinApi implements ApiService {
  FakeSpinApi(this.responses);

  final List<Object> responses;
  final sinces = <int>[];
  final cancelled = <String>[];
  var startCalls = 0;

  @override
  Future<String> startSpin(SpinRequest request) async {
    startCalls++;
    return 'job1';
  }

  @override
  Future<SpinStatus> spinStatus(String jobId, {int since = 0}) async {
    sinces.add(since);
    final r = responses.length > 1 ? responses.removeAt(0) : responses.first;
    if (r is Exception) throw r;
    return r as SpinStatus;
  }

  @override
  Future<void> cancelSpin(String jobId) async => cancelled.add(jobId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _request = SpinRequest(videoBytes: Uint8List(1), videoName: 'turn.mov', garmentFront: _png);

Widget live(FakeSpinApi api, {int pollMs = 10}) =>
    SpinScreen.live(request: _request, api: api, pollEvery: Duration(milliseconds: pollMs));

Future<void> settle(WidgetTester tester, [int ticks = 10]) async {
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  final l = l10nFor('tr');

  testWidgets('kareler geldikçe gösterilir', (tester) async {
    final api = FakeSpinApi([status('running', 1), status('running', 3, from: 1), status('done', 8, from: 3)]);
    await tester.pumpWidget(localized(live(api, pollMs: 200)));
    await tester.pump(const Duration(milliseconds: 210)); // ilk sorgu
    await tester.pump();
    expect(find.text(l.spinProgress(1, 8)), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 210));
    }
    final viewer = tester.widget<SpinViewer>(find.byType(SpinViewer));
    expect(viewer.frames, hasLength(8));
    expect(find.text(l.spinPlay), findsOneWidget);
  });

  testWidgets('since ile yalnızca yeni kareler istenir', (tester) async {
    final api = FakeSpinApi([status('running', 1), status('running', 3, from: 1), status('done', 8, from: 3)]);
    await tester.pumpWidget(localized(live(api)));
    await settle(tester);
    expect(api.sinces.take(3), [0, 1, 3]);
  });

  Future<void> openAndLeave(WidgetTester tester, FakeSpinApi api) async {
    await tester.pumpWidget(localized(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => live(api))),
          child: const Text('AÇ'),
        ),
      ),
    )));
    await tester.tap(find.text('AÇ'));
    await settle(tester, 20);
    expect(find.byType(SpinScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle(const Duration(milliseconds: 20));
    expect(find.byType(SpinScreen), findsNothing);
  }

  testWidgets('çıkışta iş iptal edilir', (tester) async {
    final api = FakeSpinApi([status('running', 1)]);
    await openAndLeave(tester, api);
    expect(api.cancelled, ['job1']);
  });

  testWidgets('bitmiş işte çıkışta iptal yok', (tester) async {
    final api = FakeSpinApi([status('done', 8)]);
    await openAndLeave(tester, api);
    expect(api.cancelled, isEmpty);
  });

  testWidgets('başarısız iş hata gösterir', (tester) async {
    final api = FakeSpinApi([status('failed', 0, error: 'x')]);
    await tester.pumpWidget(localized(live(api)));
    await settle(tester);
    expect(find.text(l.spinFailed('x')), findsOneWidget);
  });

  testWidgets('gerekçesiz başarısız iş genel mesaj gösterir', (tester) async {
    final api = FakeSpinApi([status('failed', 0)]);
    await tester.pumpWidget(localized(live(api)));
    await settle(tester);
    expect(find.text(l.spinFailed(l.spinUnknownError)), findsOneWidget);
  });

  testWidgets('geçici ağ hatasında devam eder', (tester) async {
    final api = FakeSpinApi([Exception('ağ'), status('running', 2)]);
    await tester.pumpWidget(localized(live(api)));
    await settle(tester);
    expect(find.textContaining('Dönüş oluşturulamadı'), findsNothing);
    expect(find.text(l.spinProgress(2, 8)), findsOneWidget);
  });

  testWidgets('art arda 3 ağ hatasında hata gösterilir', (tester) async {
    final api = FakeSpinApi([Exception('ağ')]);
    await tester.pumpWidget(localized(live(api)));
    await settle(tester);
    expect(find.textContaining('Dönüş oluşturulamadı'), findsOneWidget);
  });

  testWidgets('kalan süre istenen ana kare sayısından hesaplanır', (tester) async {
    // 12 ana kare istendi; 1 ana kare hazır (17 sn), toplam 48 (ara karelerle) → kalan 11 × 17 sn ≈ 4 dk
    final api = FakeSpinApi([
      SpinStatus.fromJson({
        'status': 'running',
        'total': 48,
        'done': 1,
        'frames': [
          {'index': 0, 'view': 'front', 'kind': 'key', 'image_base64': base64Encode(_png), 'render_time': 17.0},
        ],
      }),
    ]);
    await tester.pumpWidget(localized(SpinScreen.live(
      request: SpinRequest(videoBytes: Uint8List(1), videoName: 'turn.mov', garmentFront: _png, frames: 12),
      api: api,
      pollEvery: const Duration(milliseconds: 10),
    )));
    await settle(tester);
    expect(find.text(l.spinEta(4)), findsOneWidget);
  });

  testWidgets('hazır set hemen döner', (tester) async {
    await tester.pumpWidget(localized(SpinScreen.preset(
      frames: List.generate(7, (_) => MemoryImage(_png)),
      title: 'Hazır set',
    )));
    await tester.pump();
    expect(tester.widget<SpinViewer>(find.byType(SpinViewer)).frames, hasLength(7));
    expect(find.textContaining('kare hazır'), findsNothing);
    expect(find.text(l.spinPlay), findsOneWidget);
  });

  for (final (lang, b) in [('tr', Brightness.light), ('en', Brightness.dark)]) {
    testWidgets('canlı ekran $lang/${b.name} 360 taşmasız', (tester) async {
      final api = FakeSpinApi([status('running', 3)]);
      await expectNoOverflow(tester, live(api), lang: lang, b: b);
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
