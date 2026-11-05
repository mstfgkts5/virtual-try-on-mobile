import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/screens/login_screen.dart';
import 'package:see_it_on/screens/onboarding_screen.dart';

import 'helpers.dart';

void main() {
  testWidgets('kapakta künye görünür', (tester) async {
    await tester.pumpWidget(localized(const OnboardingScreen()));
    expect(find.text(l10nFor('tr').onboardingIssue), findsOneWidget);
    expect(find.text(l10nFor('tr').onboardingCoverLine2), findsOneWidget);
  });

  for (final (lang, b) in [('tr', Brightness.light), ('en', Brightness.dark)]) {
    testWidgets('tanıtım $lang/${b.name} 360 taşmasız', (tester) async {
      await expectNoOverflow(tester, const OnboardingScreen(), lang: lang, b: b);
    });
    testWidgets('giriş $lang/${b.name} 360 taşmasız', (tester) async {
      await expectNoOverflow(tester, const LoginScreen(), lang: lang, b: b);
    });
  }
}
