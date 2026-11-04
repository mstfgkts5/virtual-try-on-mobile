// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'SeeItOn';

  @override
  String get homeTitle => 'Stüdyo Kabin';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguage => 'DİL';

  @override
  String get settingsLanguageHint =>
      'Uygulamanın dili. Seçimin bu cihazda hatırlanır.';

  @override
  String get settingsLanguageTr => 'Türkçe';

  @override
  String get settingsLanguageEn => 'English';
}
