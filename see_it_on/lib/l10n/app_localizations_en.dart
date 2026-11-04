// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SeeItOn';

  @override
  String get homeTitle => 'Studio Fitting Room';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'LANGUAGE';

  @override
  String get settingsLanguageHint =>
      'The app language. Your choice is remembered on this device.';

  @override
  String get settingsLanguageTr => 'Türkçe';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get onboardingCardTitle => 'Tops • Bottoms • Full Outfits';

  @override
  String get onboardingCardSubtitle =>
      'Try it on in seconds from a single photo';

  @override
  String get onboardingBadge => 'LOCAL AI';

  @override
  String get onboardingTitle => 'Try On Any Outfit\nInstantly';

  @override
  String get onboardingSubtitle =>
      'Upload your photo, pick a garment and see how it looks on you in seconds.';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get onboardingHaveAccount => 'Already have an account? ';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get signupTitle => 'Join SeeItOn';

  @override
  String get loginSubtitle => 'Sign in to access your digital wardrobe.';

  @override
  String get signupSubtitle => 'Create an account to start trying on outfits.';

  @override
  String get loginEmailHint => 'Email address';

  @override
  String get loginPasswordHint => 'Password';

  @override
  String get loginButton => 'Log In';

  @override
  String get signupButton => 'Sign Up';

  @override
  String get loginNoAccount => 'Don\'t have an account? ';

  @override
  String get loginHaveAccount => 'Already have an account? ';

  @override
  String get loginSkipDev => 'Skip login (developer mode)';

  @override
  String get loginMissingFields => 'Please enter your email and password.';

  @override
  String get errorUnexpected => 'Something went wrong.';
}
