import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/models/spin.dart';
import 'package:see_it_on/models/tryon_request.dart';
import 'package:see_it_on/models/tryon_result.dart';
import 'package:see_it_on/screens/loading_screen.dart';
import 'package:see_it_on/screens/result_screen.dart';
import 'package:see_it_on/screens/spin_screen.dart';
import 'package:see_it_on/services/api_service.dart';
import 'package:see_it_on/services/demo_results.dart';

import 'helpers.dart';

// 1x1 şeffaf PNG
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

/// İlk çağrıda zaman aşımı atar, sonra hiç tamamlanmayan istek döner.
class _FlakyApi implements ApiService {
  int calls = 0;

  @override
  Future<TryOnResult> processVirtualTryOn(TryOnRequest request) async {
    calls++;
    if (calls == 1) throw TimeoutException('tryon');
    return Completer<TryOnResult>().future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpinApi implements ApiService {
  int startCalls = 0;

  @override
  Future<String> startSpin(SpinRequest request) async {
    startCalls++;
    return 'job$startCalls';
  }

  @override
  Future<SpinStatus> spinStatus(String jobId, {int since = 0}) async =>
      SpinStatus.fromJson({'status': 'failed', 'total': 8, 'done': 0, 'error': 'GPU dolu', 'frames': []});

  @override
  Future<void> cancelSpin(String jobId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Bellekteki dosyalardan okuyan asset paketi; olmayan dosya için hata atar.
class _MemoryBundle extends CachingAssetBundle {
  _MemoryBundle(this.files);

  final Map<String, List<int>> files;

  @override
  Future<ByteData> load(String key) async {
    final bytes = files[key];
    if (bytes == null) throw FlutterError('Unable to load asset: $key');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

final _index = jsonEncode({
  'items': [
    {
      'mannequin': 'm-m',
      'garment': 'blazer',
      'category': 'upper',
      'result': 'm-m__blazer.jpg',
      'person': 'm-m__person_upper.jpg',
      'render_time': 14.4,
    },
  ],
});

_MemoryBundle _demoBundle() => _MemoryBundle({
      DemoResults.indexAsset: utf8.encode(_index),
      '${DemoResults.folder}/m-m__blazer.jpg': _png,
      '${DemoResults.folder}/m-m__person_upper.jpg': _png,
    });

Widget _loading(ApiService api, {DemoPair? demo, AssetBundle? bundle}) {
  final screen = LoadingScreen(personImageBytes: _png, garmentImageBytes: _png, api: api, demo: demo);
  return bundle == null ? screen : DefaultAssetBundle(bundle: bundle, child: screen);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  final l = l10nFor('tr');

  test('demo dizini manken + kıyafet çiftiyle eşleşir', () {
    final demo = DemoResults.parse(_index);
    expect(demo.length, 1);
    final r = demo.lookup('m-m', 'blazer')!;
    expect(r.resultAsset, 'assets/images/demo/m-m__blazer.jpg');
    expect(r.personAsset, 'assets/images/demo/m-m__person_upper.jpg');
    expect(r.renderTimeSec, 14.4);
    expect(demo.lookup('w-m', 'blazer'), isNull);
    expect(demo.lookup(null, 'blazer'), isNull);
  });

  test('demo dizini yoksa boş liste', () async {
    final demo = await DemoResults.load(_MemoryBundle({}));
    expect(demo.length, 0);
  });

  testWidgets('hata olunca ekran kapanmaz, nedeni ve Tekrar dene görünür', (tester) async {
    final api = _FlakyApi();
    await tester.pumpWidget(localized(_loading(api)));
    await _settle(tester);

    expect(find.byType(LoadingScreen), findsOneWidget);
    expect(find.text(l.loadingErrorTitle), findsOneWidget);
    expect(find.text(l.errorTimeout), findsOneWidget);
    expect(find.text(l.loadingShowDemo), findsNothing); // kendi fotoğrafı: demo yok
  });

  testWidgets('Tekrar dene isteği yeniden gönderir', (tester) async {
    final api = _FlakyApi();
    await tester.pumpWidget(localized(_loading(api)));
    await _settle(tester);

    await tester.tap(find.text(l.actionRetry));
    await _settle(tester);

    expect(api.calls, 2);
    expect(find.text(l.loadingErrorTitle), findsNothing);
    expect(find.text(l.loadingTitle), findsOneWidget);
  });

  testWidgets('hazır manken + kıyafette sunucu yoksa demo sonucu açılır', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(localized(_loading(_FlakyApi(), demo: const DemoPair('m-m', 'blazer'), bundle: _demoBundle())));
    await _settle(tester);

    expect(find.text(l.loadingDemoHint), findsOneWidget);
    await tester.tap(find.text(l.loadingShowDemo));
    await tester.pumpAndSettle();

    final result = tester.widget<ResultScreen>(find.byType(ResultScreen));
    expect(result.isDemo, isTrue);
    expect(result.renderTimeSec, 14.4);
    expect(find.byKey(const Key('demoBadge')), findsOneWidget);
    expect(find.text(l.resultDemoBadge), findsOneWidget);
  });

  testWidgets('dizinde olmayan çift için demo düğmesi yok', (tester) async {
    await tester.pumpWidget(localized(_loading(_FlakyApi(), demo: const DemoPair('w-s', 'hoodie'), bundle: _demoBundle())));
    await _settle(tester);
    expect(find.text(l.loadingErrorTitle), findsOneWidget);
    expect(find.text(l.loadingShowDemo), findsNothing);
  });

  testWidgets('normal sonuçta demo etiketi yok', (tester) async {
    await tester.pumpWidget(localized(ResultScreen(originalImageBytes: _png, generatedImageBytes: _png)));
    expect(find.byKey(const Key('demoBadge')), findsNothing);
  });

  for (final lang in ['tr', 'en']) {
    for (final b in Brightness.values) {
      testWidgets('hata ekranı $lang/${b.name} 360 taşmasız', (tester) async {
        await expectNoOverflow(
          tester,
          _loading(_FlakyApi(), demo: const DemoPair('m-m', 'blazer'), bundle: _demoBundle()),
          lang: lang,
          b: b,
        );
        await _settle(tester);
        expect(find.text(l10nFor(lang).loadingShowDemo), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('360° dönüş hatasında Tekrar dene işi yeniden başlatır', (tester) async {
    final api = _SpinApi();
    await tester.pumpWidget(localized(SpinScreen.live(
      request: SpinRequest(videoBytes: Uint8List(1), videoName: 'turn.mov', garmentFront: _png),
      api: api,
      pollEvery: const Duration(milliseconds: 10),
    )));
    await _settle(tester);

    expect(find.text(l.spinFailed('GPU dolu')), findsOneWidget);
    await tester.tap(find.text(l.actionRetry));
    await _settle(tester);
    expect(api.startCalls, 2);
  });
}
