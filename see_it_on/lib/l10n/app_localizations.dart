import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In tr, this message translates to:
  /// **'SeeItOn'**
  String get appName;

  /// No description provided for @homeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Stüdyo Kabin'**
  String get homeTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In tr, this message translates to:
  /// **'DİL'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageHint.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanın dili. Seçimin bu cihazda hatırlanır.'**
  String get settingsLanguageHint;

  /// No description provided for @settingsLanguageTr.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get settingsLanguageTr;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @onboardingCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Üst • Alt • Tam Kıyafet'**
  String get onboardingCardTitle;

  /// No description provided for @onboardingCardSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tek fotoğrafla saniyeler içinde dene'**
  String get onboardingCardSubtitle;

  /// No description provided for @onboardingBadge.
  ///
  /// In tr, this message translates to:
  /// **'YEREL AI'**
  String get onboardingBadge;

  /// No description provided for @onboardingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Her Kıyafeti\nAnında Dene'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafını yükle, bir kıyafet seç ve saniyeler içinde üzerinde gerçekçi görünümünü izle.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingStart.
  ///
  /// In tr, this message translates to:
  /// **'Hemen Başla'**
  String get onboardingStart;

  /// No description provided for @onboardingHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? '**
  String get onboardingHaveAccount;

  /// No description provided for @loginTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Hoş Geldin'**
  String get loginTitle;

  /// No description provided for @signupTitle.
  ///
  /// In tr, this message translates to:
  /// **'SeeItOn\'a Katıl'**
  String get signupTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Dijital gardırobuna erişmek için giriş yap.'**
  String get loginSubtitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kıyafetleri üzerinde denemeye başlamak için hesap oluştur.'**
  String get signupSubtitle;

  /// No description provided for @loginEmailHint.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get loginPasswordHint;

  /// No description provided for @loginButton.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get loginButton;

  /// No description provided for @signupButton.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get signupButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? '**
  String get loginNoAccount;

  /// No description provided for @loginHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? '**
  String get loginHaveAccount;

  /// No description provided for @loginSkipDev.
  ///
  /// In tr, this message translates to:
  /// **'Girişi atla (geliştirici modu)'**
  String get loginSkipDev;

  /// No description provided for @loginMissingFields.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen e-posta ve şifrenizi girin.'**
  String get loginMissingFields;

  /// No description provided for @errorUnexpected.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen bir hata oluştu.'**
  String get errorUnexpected;

  /// No description provided for @homeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kendi stilini saniyeler içinde oluştur.'**
  String get homeSubtitle;

  /// No description provided for @homeWhatToTry.
  ///
  /// In tr, this message translates to:
  /// **'NE DENEMEK İSTİYORSUN?'**
  String get homeWhatToTry;

  /// No description provided for @categoryUpper.
  ///
  /// In tr, this message translates to:
  /// **'Üst Giyim'**
  String get categoryUpper;

  /// No description provided for @categoryLower.
  ///
  /// In tr, this message translates to:
  /// **'Alt Giyim'**
  String get categoryLower;

  /// No description provided for @categoryOverall.
  ///
  /// In tr, this message translates to:
  /// **'Tam Kıyafet'**
  String get categoryOverall;

  /// No description provided for @categoryUpperHint.
  ///
  /// In tr, this message translates to:
  /// **'Tişört, gömlek, kazak, ceket\nveya hırka fotoğrafı'**
  String get categoryUpperHint;

  /// No description provided for @categoryLowerHint.
  ///
  /// In tr, this message translates to:
  /// **'Pantolon, etek veya şort fotoğrafı. Şort/kısa etek için\nüzerinde kısa kıyafet olan bir fotoğraf daha iyi sonuç verir'**
  String get categoryLowerHint;

  /// No description provided for @categoryOverallHint.
  ///
  /// In tr, this message translates to:
  /// **'Elbise veya tulum\nfotoğrafı (tam boy kişi fotoğrafı önerilir)'**
  String get categoryOverallHint;

  /// No description provided for @homeStepPerson.
  ///
  /// In tr, this message translates to:
  /// **'ADIM 1  •  Kendi Fotoğrafın'**
  String get homeStepPerson;

  /// No description provided for @homeStepGarment.
  ///
  /// In tr, this message translates to:
  /// **'ADIM 2  •  {category}'**
  String homeStepGarment(String category);

  /// No description provided for @homeUploadPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Yükle'**
  String get homeUploadPhoto;

  /// No description provided for @homeUploadPhotoHint.
  ///
  /// In tr, this message translates to:
  /// **'Net bir boy aynası selfie\'si\nveya düz durduğunuz bir fotoğraf'**
  String get homeUploadPhotoHint;

  /// No description provided for @homeUploadGarment.
  ///
  /// In tr, this message translates to:
  /// **'Kıyafet Yükle'**
  String get homeUploadGarment;

  /// No description provided for @homeGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeri'**
  String get homeGallery;

  /// No description provided for @homeCamera.
  ///
  /// In tr, this message translates to:
  /// **'Kamera'**
  String get homeCamera;

  /// No description provided for @homeMannequin.
  ///
  /// In tr, this message translates to:
  /// **'Manken'**
  String get homeMannequin;

  /// No description provided for @homeSample.
  ///
  /// In tr, this message translates to:
  /// **'Örnek'**
  String get homeSample;

  /// No description provided for @homeTryOn.
  ///
  /// In tr, this message translates to:
  /// **'Üzerimde Gör'**
  String get homeTryOn;

  /// No description provided for @homeTryOnBadge.
  ///
  /// In tr, this message translates to:
  /// **'Try On'**
  String get homeTryOnBadge;

  /// No description provided for @homeNeedPerson.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen önce kendi fotoğrafınızı (Adım 1) yükleyin!'**
  String get homeNeedPerson;

  /// No description provided for @homeNeedGarment.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen denemek istediğiniz kıyafeti (Adım 2) seçin!'**
  String get homeNeedGarment;

  /// No description provided for @homeRackTitle.
  ///
  /// In tr, this message translates to:
  /// **'ÖRNEK KIYAFET RAFI'**
  String get homeRackTitle;

  /// No description provided for @homeRackSelect.
  ///
  /// In tr, this message translates to:
  /// **'BU PARÇAYI SEÇ'**
  String get homeRackSelect;

  /// No description provided for @homeRackSelected.
  ///
  /// In tr, this message translates to:
  /// **'{garment} seçildi. Şimdi fotoğrafını ekle ve \"Üzerimde Gör\"e bas.'**
  String homeRackSelected(String garment);

  /// No description provided for @homeSamplePickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Örnek {category}'**
  String homeSamplePickerTitle(String category);

  /// No description provided for @homeMannequinPickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hazır Manken Seç'**
  String get homeMannequinPickerTitle;

  /// No description provided for @homeMannequinPickerHint.
  ///
  /// In tr, this message translates to:
  /// **'Kendi fotoğrafın yerine bir bedeni seçerek dene.'**
  String get homeMannequinPickerHint;

  /// No description provided for @navTryOn.
  ///
  /// In tr, this message translates to:
  /// **'DENE'**
  String get navTryOn;

  /// No description provided for @navWardrobe.
  ///
  /// In tr, this message translates to:
  /// **'GARDIROP'**
  String get navWardrobe;

  /// No description provided for @navProfile.
  ///
  /// In tr, this message translates to:
  /// **'PROFİL'**
  String get navProfile;

  /// No description provided for @mannequinWomen.
  ///
  /// In tr, this message translates to:
  /// **'Kadın {size}'**
  String mannequinWomen(String size);

  /// No description provided for @mannequinMen.
  ///
  /// In tr, this message translates to:
  /// **'Erkek {size}'**
  String mannequinMen(String size);

  /// No description provided for @garmentBlazer.
  ///
  /// In tr, this message translates to:
  /// **'Ekose Blazer'**
  String get garmentBlazer;

  /// No description provided for @garmentJeans.
  ///
  /// In tr, this message translates to:
  /// **'Mavi Kot'**
  String get garmentJeans;

  /// No description provided for @garmentChino.
  ///
  /// In tr, this message translates to:
  /// **'Bej Chino'**
  String get garmentChino;

  /// No description provided for @garmentTrousers.
  ///
  /// In tr, this message translates to:
  /// **'Lacivert Pantolon'**
  String get garmentTrousers;

  /// No description provided for @garmentSkirt.
  ///
  /// In tr, this message translates to:
  /// **'Pliseli Etek'**
  String get garmentSkirt;

  /// No description provided for @garmentShorts.
  ///
  /// In tr, this message translates to:
  /// **'Kot Şort'**
  String get garmentShorts;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
