import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/consent_controller.dart';
import 'package:see_it_on/screens/auth_gate.dart';
import 'package:see_it_on/screens/consent_screen.dart';

import 'helpers.dart';

void main() {
  final tr = l10nFor('tr');

  testWidgets('kutu işaretlenmeden onay düğmesi kapalı, işaretlenince rıza verilir', (tester) async {
    final c = ConsentController.inMemory();
    await tester.pumpWidget(localized(ConsentScreen(controller: c)));
    expect(find.text(tr.consentTitle), findsOneWidget);

    await tester.tap(find.text(tr.consentAccept));
    await tester.pump();
    expect(c.value, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text(tr.consentAccept));
    await tester.pump();
    expect(c.value, isTrue);
  });

  testWidgets('metin dört bölümü içerir', (tester) async {
    await tester.pumpWidget(localized(ConsentScreen(controller: ConsentController.inMemory())));
    for (final t in [tr.consentDataTitle, tr.consentPurposeTitle, tr.consentStorageTitle, tr.consentRightsTitle]) {
      await tester.scrollUntilVisible(find.text(t), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text(t), findsOneWidget);
    }
  });

  testWidgets('salt okunur modda rıza geri çekilir', (tester) async {
    final c = ConsentController.inMemory(true);
    await tester.pumpWidget(localized(Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ConsentScreen(readOnly: true, controller: c)),
        ),
        child: const Text('ROOT'),
      ),
    )));
    await tester.tap(find.text('ROOT'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);
    await tester.tap(find.text(tr.consentWithdraw));
    await tester.pumpAndSettle();
    expect(c.value, isFalse);
    expect(find.text('ROOT'), findsOneWidget);
  });

  testWidgets('ConsentGate: rıza yoksa metin, verilince içerik', (tester) async {
    final c = ConsentController.inMemory();
    await tester.pumpWidget(localized(ConsentGate(controller: c, child: const Text('HOME'))));
    expect(find.text('HOME'), findsNothing);
    expect(find.text(tr.consentTitle), findsOneWidget);
    await c.accept();
    await tester.pump();
    expect(find.text('HOME'), findsOneWidget);
  });

  for (final (lang, b) in [('tr', Brightness.light), ('en', Brightness.dark)]) {
    testWidgets('onay ekranı $lang/${b.name} 360 taşmasız', (tester) async {
      await expectNoOverflow(tester, ConsentScreen(controller: ConsentController.inMemory()), lang: lang, b: b);
    });
  }
}
