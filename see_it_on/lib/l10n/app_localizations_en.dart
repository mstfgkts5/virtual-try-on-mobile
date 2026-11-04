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

  @override
  String get homeSubtitle => 'Build your style in seconds.';

  @override
  String get homeWhatToTry => 'WHAT DO YOU WANT TO TRY?';

  @override
  String get categoryUpper => 'Upper wear';

  @override
  String get categoryLower => 'Lower wear';

  @override
  String get categoryOverall => 'Full outfit';

  @override
  String get categoryUpperHint =>
      'A photo of a t-shirt, shirt, sweater,\njacket or cardigan';

  @override
  String get categoryLowerHint =>
      'A photo of trousers, a skirt or shorts. For shorts/short skirts,\na photo wearing short clothes gives better results';

  @override
  String get categoryOverallHint =>
      'A photo of a dress or jumpsuit\n(a full-body person photo is recommended)';

  @override
  String get homeStepPerson => 'STEP 1  •  Your Photo';

  @override
  String homeStepGarment(String category) {
    return 'STEP 2  •  $category';
  }

  @override
  String get homeUploadPhoto => 'Upload Photo';

  @override
  String get homeUploadPhotoHint =>
      'A clear full-length mirror selfie\nor a photo of you standing straight';

  @override
  String get homeUploadGarment => 'Upload Garment';

  @override
  String get homeGallery => 'Gallery';

  @override
  String get homeCamera => 'Camera';

  @override
  String get homeMannequin => 'Model';

  @override
  String get homeSample => 'Sample';

  @override
  String get homeTryOn => 'Try It On';

  @override
  String get homeTryOnBadge => 'AI';

  @override
  String get homeNeedPerson => 'Please upload your photo first (Step 1)!';

  @override
  String get homeNeedGarment => 'Please choose a garment to try on (Step 2)!';

  @override
  String get homeRackTitle => 'SAMPLE GARMENT RACK';

  @override
  String get homeRackSelect => 'PICK THIS ITEM';

  @override
  String homeRackSelected(String garment) {
    return '$garment selected. Now add your photo and tap \"Try It On\".';
  }

  @override
  String homeSamplePickerTitle(String category) {
    return 'Sample $category';
  }

  @override
  String get homeMannequinPickerTitle => 'Choose a Model';

  @override
  String get homeMannequinPickerHint =>
      'Pick a body size instead of your own photo.';

  @override
  String get navTryOn => 'TRY ON';

  @override
  String get navWardrobe => 'WARDROBE';

  @override
  String get navProfile => 'PROFILE';

  @override
  String mannequinWomen(String size) {
    return 'Women $size';
  }

  @override
  String mannequinMen(String size) {
    return 'Men $size';
  }

  @override
  String get garmentBlazer => 'Plaid Blazer';

  @override
  String get garmentJeans => 'Blue Jeans';

  @override
  String get garmentChino => 'Beige Chinos';

  @override
  String get garmentTrousers => 'Navy Trousers';

  @override
  String get garmentSkirt => 'Pleated Skirt';

  @override
  String get garmentShorts => 'Denim Shorts';
}
