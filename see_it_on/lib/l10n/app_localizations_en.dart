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

  @override
  String get categoryBadgeUpper => 'UPPER BODY';

  @override
  String get categoryBadgeLower => 'LOWER BODY';

  @override
  String get categoryBadgeOverall => 'FULL OUTFIT';

  @override
  String get loadingEngine => 'CATVTON • LOCAL GPU';

  @override
  String loadingProgress(String percent) {
    return 'PROGRESS: $percent%';
  }

  @override
  String get loadingModelRunning => 'DIFFUSION MODEL RUNNING';

  @override
  String get loadingTitle => 'Dressing you up •';

  @override
  String get loadingEta => 'Estimated time ~40 s';

  @override
  String get loadingFinalTouches => 'Final touches...';

  @override
  String get loadingProcessing => 'Processing...';

  @override
  String get loadingStepMask => 'Body mask';

  @override
  String get loadingStepMaskDesc => 'DensePose + SCHP find the region to dress';

  @override
  String get loadingStepDiffusion => 'Diffusion (30 steps)';

  @override
  String get loadingStepDiffusionDesc =>
      'CatVTON draws the garment onto the person';

  @override
  String get loadingStepBlend => 'Blending';

  @override
  String get loadingStepBlendDesc =>
      'Face and background are kept from the original photo';

  @override
  String get statusDone => 'DONE';

  @override
  String get statusProcessing => 'PROCESSING';

  @override
  String get statusQueued => 'QUEUED';

  @override
  String get loadingCancel => 'Cancel';

  @override
  String loadingFailed(String reason) {
    return 'Try-on failed: $reason';
  }

  @override
  String get errorTimeout =>
      'The server took too long to respond. Please try again.';

  @override
  String get errorBackendOffline =>
      'Can\'t reach the AI server. Is the backend running?';

  @override
  String errorServer(String code) {
    return 'Server error ($code)';
  }

  @override
  String resultTitle(String category) {
    return '$category result';
  }

  @override
  String get resultOverline => 'STUDIO COMPARISON';

  @override
  String get resultHeading => 'Your Look';

  @override
  String get resultSubtitle =>
      'Review the try-on result and compare the details.';

  @override
  String get resultTabSplit => 'Slider';

  @override
  String get resultTabSide => 'Side by Side';

  @override
  String get resultTabFade => 'Fade';

  @override
  String get resultBefore => '• BEFORE';

  @override
  String get resultAfter => '✨ AFTER';

  @override
  String get resultFullScreen => 'Full Screen';

  @override
  String get resultSaveToGallery => 'Save to gallery';

  @override
  String get resultDetails => 'Details';

  @override
  String get resultEngine => 'CatVTON • Local GPU';

  @override
  String get resultRenderTime => 'Render Time';

  @override
  String resultSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get resultRenderTimeDesc => 'Measured on the local graphics card';

  @override
  String get resultCategory => 'Category';

  @override
  String get resultCategoryDesc => 'The region the model dressed';

  @override
  String get resultSaving => 'Saving...';

  @override
  String get resultAddToWardrobe => 'Confirm and Add to Wardrobe';

  @override
  String get resultNeedLogin => 'Please log in first.';

  @override
  String get resultWardrobeSaved => '✨ Look added to your wardrobe!';

  @override
  String resultWardrobeError(String reason) {
    return 'Could not save: $reason';
  }

  @override
  String get resultGallerySaved => 'Image saved to gallery.';

  @override
  String get resultGalleryWeb =>
      'Browsers have no gallery; use Share, or right-click the full-screen image to save it.';

  @override
  String get resultGalleryFailed => 'Could not save the image.';

  @override
  String get resultShareText =>
      'Check out the AI virtual try-on look I made with SeeItOn! ✨ #SeeItOn #VirtualTryOn';
}
