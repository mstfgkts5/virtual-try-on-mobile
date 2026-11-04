import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/design/tokens.dart';
import 'package:see_it_on/models/tryon_request.dart';
import 'package:see_it_on/models/tryon_result.dart';
import 'package:see_it_on/screens/loading_screen.dart';
import 'package:see_it_on/screens/result_screen.dart';
import 'package:see_it_on/services/api_service.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Backend'e gitmeyen, hiç tamamlanmayan sahte servis: yükleme ekranı açık kalır.
class _NeverApi implements ApiService {
  int calls = 0;

  @override
  Future<TryOnResult> processVirtualTryOn(TryOnRequest request) {
    calls++;
    return Completer<TryOnResult>().future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 1x1 şeffaf PNG: Image.memory'nin çözebileceği en küçük geçerli görsel
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

Future<void> _openAndSave(WidgetTester tester, FakeWardrobeRepository repo) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(localized(ResultScreen(
    originalImageBytes: _png,
    generatedImageBytes: _png,
    category: 'lower',
    renderTimeSec: 40,
    wardrobe: repo,
  )));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10nFor('tr').resultAddToWardrobe));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('gardıroba kategoriyle kaydeder', (tester) async {
    final repo = FakeWardrobeRepository();
    await _openAndSave(tester, repo);
    expect(repo.added, ['lower']);
    expect(find.text(l10nFor('tr').resultWardrobeSaved), findsOneWidget);
  });

  testWidgets('görsel altında italik künye yazısı', (tester) async {
    await tester.pumpWidget(localized(ResultScreen(
      originalImageBytes: _png,
      generatedImageBytes: _png,
      category: 'lower',
      renderTimeSec: 40,
      wardrobe: FakeWardrobeRepository(),
    )));
    expect(find.text(l10nFor('tr').resultCaption('Alt Giyim', '40.0')), findsOneWidget);
  });

  testWidgets('sonuç ekranı EN/koyu 360 taşmasız', (tester) async {
    await expectNoOverflow(
      tester,
      ResultScreen(
        originalImageBytes: _png,
        generatedImageBytes: _png,
        category: 'overall',
        renderTimeSec: 41.3,
        wardrobe: FakeWardrobeRepository(),
      ),
      lang: 'en',
      b: Brightness.dark,
    );
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, SeeItOnTokens.dark.paper);
  });

  testWidgets('yükleme ekranı TR/açık 360 taşmasız, istek sahte servise gider', (tester) async {
    final api = _NeverApi();
    await expectNoOverflow(
      tester,
      LoadingScreen(personImageBytes: _png, garmentImageBytes: _png, category: 'lower', api: api),
      lang: 'tr',
      b: Brightness.light,
    );
    expect(api.calls, 1);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, SeeItOnTokens.light.paper);
  });

  testWidgets('oturum yoksa giriş uyarısı', (tester) async {
    final repo = FakeWardrobeRepository(email: null);
    await _openAndSave(tester, repo);
    expect(repo.added, isEmpty);
    expect(find.text(l10nFor('tr').resultNeedLogin), findsOneWidget);
  });
}
