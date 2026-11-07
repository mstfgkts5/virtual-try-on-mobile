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
  String get loadingEta => 'Estimated time ~20 s';

  @override
  String get loadingFinalTouches => 'Final touches...';

  @override
  String get loadingProcessing => 'Processing...';

  @override
  String get loadingStepMask => 'Body mask';

  @override
  String get loadingStepMaskDesc => 'DensePose + SCHP find the region to dress';

  @override
  String get loadingStepDiffusion => 'Diffusion (15 steps)';

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

  @override
  String get wardrobeTitle => 'MY WARDROBE';

  @override
  String wardrobeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved looks',
      one: '1 saved look',
      zero: 'No looks yet',
    );
    return '$_temp0';
  }

  @override
  String wardrobeDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: 'Yesterday',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get wardrobeEmptyTitle => 'Your wardrobe is empty';

  @override
  String get wardrobeEmptyBody =>
      'Try on an outfit, then tap \"Add to Wardrobe\" on the result screen to see it here.';

  @override
  String get wardrobeEmptyCta => 'Try an Outfit';

  @override
  String get authErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authErrorEmailTaken =>
      'An account with this email already exists. Try logging in.';

  @override
  String get authErrorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get authErrorInvalidEmail => 'Enter a valid email address.';

  @override
  String get authErrorNetwork =>
      'No internet connection, or the server can\'t be reached.';

  @override
  String get authErrorPasswordTooShort =>
      'Password must be at least 6 characters.';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get settingsAccount => 'ACCOUNT';

  @override
  String settingsSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get authErrorRateLimit =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get wardrobeHeading => 'Your Looks';

  @override
  String get wardrobeFilterAll => 'All';

  @override
  String get wardrobeSignInTitle => 'Your wardrobe is waiting';

  @override
  String get wardrobeSignInBody =>
      'Log in to save the looks you try on and see them here.';

  @override
  String get wardrobeLoadError =>
      'Couldn\'t load your wardrobe. Check your internet connection.';

  @override
  String get wardrobeRetry => 'Try again';

  @override
  String get wardrobeShare => 'Share';

  @override
  String get wardrobeDelete => 'Delete';

  @override
  String get wardrobeDeleteTitle => 'Delete this look?';

  @override
  String get wardrobeDeleteBody =>
      'This look will be permanently removed from your wardrobe.';

  @override
  String get wardrobeDeleteConfirm => 'Delete';

  @override
  String get wardrobeCancel => 'Cancel';

  @override
  String get wardrobeDeleted => 'Look deleted.';

  @override
  String get wardrobeDeleteFailed => 'Couldn\'t delete the look. Try again.';

  @override
  String get wardrobeShareFailed => 'Couldn\'t share the image.';

  @override
  String get settingsAppearance => 'APPEARANCE';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get onboardingIssue => 'No. 01 — The Fitting Room';

  @override
  String resultCaption(String category, String seconds) {
    return '$category — $seconds s, local GPU';
  }

  @override
  String get cameraHint => 'Show your full body, arms slightly apart';

  @override
  String get cameraUse => 'Use photo';

  @override
  String get cameraRetake => 'Retake';

  @override
  String get cameraSwitch => 'Switch camera';

  @override
  String get cameraDenied => 'Camera permission was denied.';

  @override
  String get cameraUnavailable => 'No camera found on this device.';

  @override
  String get cameraUseGallery => 'Choose from gallery';

  @override
  String get cameraCapture => 'Take photo';

  @override
  String get cameraClose => 'Close';

  @override
  String get spinTitle => '360° Spin';

  @override
  String spinProgress(int done, int total) {
    return '$done of $total frames ready';
  }

  @override
  String spinEta(int minutes) {
    return 'About $minutes min left';
  }

  @override
  String get spinPlay => 'Spin';

  @override
  String get spinStop => 'Stop';

  @override
  String get spinDragHint => 'Drag left or right to rotate';

  @override
  String spinFailed(String reason) {
    return 'Could not create the spin: $reason';
  }

  @override
  String get spinCancelled => 'The job was cancelled.';

  @override
  String get spinStarting => 'Uploading the video…';

  @override
  String get homeSpinVideo => 'Turn video';

  @override
  String get homeSpinSelected => '360° spin video';

  @override
  String get homeGarmentBack => 'Back image (optional)';

  @override
  String get homeSpinPreset => 'Ready-made 360° set';

  @override
  String get homeSpinHint =>
      'Keep your feet in place and turn slowly (10–20 s)';
}
