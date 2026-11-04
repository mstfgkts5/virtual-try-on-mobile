import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/screens/result_screen.dart';

import 'fakes.dart';
import 'helpers.dart';

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

  testWidgets('oturum yoksa giriş uyarısı', (tester) async {
    final repo = FakeWardrobeRepository(email: null);
    await _openAndSave(tester, repo);
    expect(repo.added, isEmpty);
    expect(find.text(l10nFor('tr').resultNeedLogin), findsOneWidget);
  });
}
