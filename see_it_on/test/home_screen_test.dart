import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/l10n_ext.dart';
import 'package:see_it_on/screens/home_screen.dart';

import 'helpers.dart';

void main() {
  testWidgets('EN kategori seçici', (tester) async {
    await tester.pumpWidget(localized(const HomeScreen(), lang: 'en'));
    // Raftaki kıyafetin altında da kategori adı yazdığı için birden fazla görünebilir
    expect(find.text('Upper wear'), findsWidgets);
    expect(find.text('Lower wear'), findsWidgets);
    expect(find.text('Full outfit'), findsWidgets);
    expect(find.text('Üst Giyim'), findsNothing);
  });

  testWidgets('TR başlık', (tester) async {
    await tester.pumpWidget(localized(const HomeScreen()));
    expect(find.text('Stüdyo Kabin'), findsOneWidget);
  });

  testWidgets('375 genişlikte EN taşma yok', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(localized(const HomeScreen(), lang: 'en'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('categoryName iki dilde', () {
    expect(categoryName(l10nFor('en'), 'lower'), 'Lower wear');
    expect(categoryName(l10nFor('tr'), 'overall'), 'Tam Kıyafet');
  });
}
