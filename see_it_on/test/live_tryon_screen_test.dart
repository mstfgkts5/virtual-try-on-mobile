import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/models/tryon_request.dart';
import 'package:see_it_on/models/tryon_result.dart';
import 'package:see_it_on/screens/live_tryon_screen.dart';
import 'package:see_it_on/screens/loading_screen.dart';
import 'package:see_it_on/services/api_service.dart';
import 'package:see_it_on/services/camera_service.dart';

import 'helpers.dart';

// 1x1 şeffaf PNG
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class FakeCamera implements CameraService {
  int captures = 0;
  bool disposed = false;

  @override
  Future<void> init({bool front = true}) async => disposed = false;
  @override
  Widget preview() => const ColoredBox(color: Colors.grey, key: ValueKey('cam-preview'));
  @override
  Future<Uint8List> capture() async {
    captures++;
    return _png;
  }

  @override
  Future<void> switchCamera() async {}
  @override
  Future<void> dispose() async => disposed = true;
  @override
  bool get hasMultipleCameras => false;
  @override
  bool get isFront => true;
}

class FakeApi implements ApiService {
  FakeApi({this.fail = false});
  final bool fail;
  final requests = <TryOnRequest>[];

  @override
  Future<TryOnResult> processVirtualTryOn(TryOnRequest request) async {
    requests.add(request);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (fail) throw Exception('ağ yok');
    return TryOnResult(id: '1', title: 'upper', resultImageBytes: _png, renderTimeSec: 2.2);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _garments = [
  LiveGarment(id: 'blazer', name: 'Blazer', category: 'upper', bytes: _png),
  LiveGarment(id: 'jeans', name: 'Kot', category: 'lower', bytes: _png),
];

Widget live(FakeCamera cam, FakeApi api) => LiveTryOnScreen(
      camera: cam,
      api: api,
      garments: _garments,
      pause: const Duration(milliseconds: 10),
    );

Future<void> run(WidgetTester tester, [int ticks = 10]) async {
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// Ekranı kapatıp döngünün bekleyen zamanlayıcılarının bitmesini bekler.
Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await run(tester, 5);
}

void main() {
  final l = l10nFor('tr');

  testWidgets('kıyafet seçilmeden istek gönderilmez', (tester) async {
    final cam = FakeCamera(), api = FakeApi();
    await tester.pumpWidget(localized(live(cam, api)));
    await run(tester);
    expect(find.byKey(const ValueKey('cam-preview')), findsOneWidget);
    expect(find.text(l.liveHint), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('kıyafet seçilince önizleme isteği gider ve sonuç kameranın üstünde görünür', (tester) async {
    final cam = FakeCamera(), api = FakeApi();
    await tester.pumpWidget(localized(live(cam, api)));
    await run(tester, 2);
    await tester.tap(find.byKey(const ValueKey('live-garment-blazer')));
    await run(tester);
    expect(api.requests, isNotEmpty);
    expect(api.requests.first.preview, isTrue);
    expect(api.requests.first.category, 'upper');
    expect(api.requests.first.toFieldsMap()['preview'], 'true');
    expect(find.byKey(const ValueKey('live-result')), findsOneWidget);
    await finish(tester);
  });

  testWidgets('sonuç gelince yeni kare çekilir (döngü)', (tester) async {
    final cam = FakeCamera(), api = FakeApi();
    await tester.pumpWidget(localized(live(cam, api)));
    await run(tester, 2);
    await tester.tap(find.byKey(const ValueKey('live-garment-blazer')));
    await run(tester, 20);
    expect(api.requests.length, greaterThanOrEqualTo(3));
    expect(cam.captures, greaterThanOrEqualTo(api.requests.length));
    await finish(tester);
  });

  testWidgets('seçili kıyafete tekrar dokununca döngü durur', (tester) async {
    final cam = FakeCamera(), api = FakeApi();
    await tester.pumpWidget(localized(live(cam, api)));
    await run(tester, 2);
    await tester.tap(find.byKey(const ValueKey('live-garment-blazer')));
    await run(tester);
    await tester.tap(find.byKey(const ValueKey('live-garment-blazer')));
    await run(tester, 4);
    final after = api.requests.length;
    await run(tester, 10);
    expect(api.requests.length, after);
    expect(find.byKey(const ValueKey('live-result')), findsNothing);
  });

  testWidgets('üst/alt seçimi şeridi süzer ve çalışan döngüyü durdurur', (tester) async {
    final cam = FakeCamera(), api = FakeApi();
    await tester.pumpWidget(localized(live(cam, api)));
    await run(tester, 2);
    expect(find.byKey(const ValueKey('live-garment-blazer')), findsOneWidget);
    expect(find.byKey(const ValueKey('live-garment-jeans')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('live-garment-blazer')));
    await run(tester);
    await tester.tap(find.text(l.categoryLower));
    await run(tester, 4);
    final after = api.requests.length;
    expect(find.byKey(const ValueKey('live-garment-blazer')), findsNothing);
    expect(find.byKey(const ValueKey('live-garment-jeans')), findsOneWidget);
    expect(find.byKey(const ValueKey('live-result')), findsNothing);
    await run(tester, 10);
    expect(api.requests.length, after);
    await tester.tap(find.byKey(const ValueKey('live-garment-jeans')));
    await run(tester);
    expect(api.requests.last.category, 'lower');
    await finish(tester);
  });

  testWidgets('art arda hatada döngü durur ve mesaj görünür', (tester) async {
    final cam = FakeCamera(), api = FakeApi(fail: true);
    await tester.pumpWidget(localized(live(cam, api)));
    await run(tester, 2);
    await tester.tap(find.byKey(const ValueKey('live-garment-blazer')));
    await run(tester, 30);
    expect(find.textContaining('Bağlantı sorunu'), findsOneWidget);
    final after = api.requests.length;
    await run(tester, 10);
    expect(api.requests.length, after);
  });

  testWidgets('Kaydet son kareyi tam kaliteyle LoadingScreen e gönderir', (tester) async {
    final cam = FakeCamera(), api = FakeApi();
    await tester.pumpWidget(localized(live(cam, api)));
    await run(tester, 2);
    await tester.tap(find.byKey(const ValueKey('live-garment-blazer')));
    await run(tester);
    await tester.tap(find.text(l.liveSave));
    await tester.pump();
    final loading = tester.widget<LoadingScreen>(find.byType(LoadingScreen, skipOffstage: false));
    expect(loading.category, 'upper');
    expect(loading.personImageBytes, _png);
    await finish(tester);
  });

  testWidgets('çıkınca kamera bırakılır ve döngü durur', (tester) async {
    final cam = FakeCamera(), api = FakeApi();
    await tester.pumpWidget(localized(live(cam, api)));
    await run(tester, 2);
    await tester.tap(find.byKey(const ValueKey('live-garment-blazer')));
    await run(tester, 4);
    await tester.pumpWidget(localized(const SizedBox()));
    final after = api.requests.length;
    await run(tester, 10);
    expect(cam.disposed, isTrue);
    expect(api.requests.length, lessThanOrEqualTo(after + 1));
  });

  for (final (lang, b) in [('tr', Brightness.light), ('en', Brightness.dark)]) {
    testWidgets('canlı ekran $lang/${b.name} 360 taşmasız', (tester) async {
      await expectNoOverflow(tester, live(FakeCamera(), FakeApi()), lang: lang, b: b);
    });
  }
}
