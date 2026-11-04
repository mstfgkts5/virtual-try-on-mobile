import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/design/theme.dart';
import 'package:see_it_on/core/l10n_ext.dart';
import 'package:see_it_on/core/locale_controller.dart';

/// Bir ekranı verilen dilde ve temada, uygulamadaki çeviri delegeleriyle sarar.
Widget localized(Widget home, {String lang = 'tr', Brightness brightness = Brightness.light}) => MaterialApp(
      locale: Locale(lang),
      theme: buildTheme(brightness),
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

AppLocalizations l10nFor(String lang) => lookupAppLocalizations(Locale(lang));

/// Ekranı 360×800 dar telefonda açar; taşma (RenderFlex overflow) veya başka hata olmamalı.
Future<void> expectNoOverflow(
  WidgetTester tester,
  Widget screen, {
  required String lang,
  required Brightness b,
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(localized(screen, lang: lang, brightness: b));
  await tester.pump(const Duration(milliseconds: 300));
  expect(tester.takeException(), isNull, reason: '${screen.runtimeType} $lang/${b.name}');
}
