import 'package:flutter/material.dart';
import 'package:see_it_on/core/l10n_ext.dart';
import 'package:see_it_on/core/locale_controller.dart';

/// Bir ekranı verilen dilde, uygulamadaki çeviri delegeleriyle sarar.
Widget localized(Widget home, {String lang = 'tr'}) => MaterialApp(
      locale: Locale(lang),
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

AppLocalizations l10nFor(String lang) => lookupAppLocalizations(Locale(lang));
