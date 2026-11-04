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

  @override
  String get onboardingCardTitle => 'Üst • Alt • Tam Kıyafet';

  @override
  String get onboardingCardSubtitle => 'Tek fotoğrafla saniyeler içinde dene';

  @override
  String get onboardingBadge => 'YEREL AI';

  @override
  String get onboardingTitle => 'Her Kıyafeti\nAnında Dene';

  @override
  String get onboardingSubtitle =>
      'Fotoğrafını yükle, bir kıyafet seç ve saniyeler içinde üzerinde gerçekçi görünümünü izle.';

  @override
  String get onboardingStart => 'Hemen Başla';

  @override
  String get onboardingHaveAccount => 'Zaten hesabın var mı? ';

  @override
  String get loginTitle => 'Tekrar Hoş Geldin';

  @override
  String get signupTitle => 'SeeItOn\'a Katıl';

  @override
  String get loginSubtitle => 'Dijital gardırobuna erişmek için giriş yap.';

  @override
  String get signupSubtitle =>
      'Kıyafetleri üzerinde denemeye başlamak için hesap oluştur.';

  @override
  String get loginEmailHint => 'E-posta adresi';

  @override
  String get loginPasswordHint => 'Şifre';

  @override
  String get loginButton => 'Giriş Yap';

  @override
  String get signupButton => 'Kayıt Ol';

  @override
  String get loginNoAccount => 'Hesabın yok mu? ';

  @override
  String get loginHaveAccount => 'Zaten hesabın var mı? ';

  @override
  String get loginSkipDev => 'Girişi atla (geliştirici modu)';

  @override
  String get loginMissingFields => 'Lütfen e-posta ve şifrenizi girin.';

  @override
  String get errorUnexpected => 'Beklenmeyen bir hata oluştu.';
}
