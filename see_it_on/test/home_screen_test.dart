import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/design/tokens.dart';
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

  for (final (lang, b) in [('en', Brightness.dark), ('tr', Brightness.light)]) {
    testWidgets('ana ekran $lang/${b.name} 360 taşmasız', (tester) async {
      await expectNoOverflow(tester, const HomeScreen(), lang: lang, b: b);
    });
  }

  testWidgets('koyu temada ana ekran zemini paper belirteci', (tester) async {
    await tester.pumpWidget(localized(const HomeScreen(), brightness: Brightness.dark));
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, SeeItOnTokens.dark.paper);
  });

  test('categoryName iki dilde', () {
    expect(categoryName(l10nFor('en'), 'lower'), 'Lower wear');
    expect(categoryName(l10nFor('tr'), 'overall'), 'Tam Kıyafet');
  });
}
