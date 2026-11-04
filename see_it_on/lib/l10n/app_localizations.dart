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

  /// No description provided for @categoryBadgeUpper.
  ///
  /// In tr, this message translates to:
  /// **'ÜST GİYİM'**
  String get categoryBadgeUpper;

  /// No description provided for @categoryBadgeLower.
  ///
  /// In tr, this message translates to:
  /// **'ALT GİYİM'**
  String get categoryBadgeLower;

  /// No description provided for @categoryBadgeOverall.
  ///
  /// In tr, this message translates to:
  /// **'TAM KIYAFET'**
  String get categoryBadgeOverall;

  /// No description provided for @loadingEngine.
  ///
  /// In tr, this message translates to:
  /// **'CATVTON • YEREL GPU'**
  String get loadingEngine;

  /// No description provided for @loadingProgress.
  ///
  /// In tr, this message translates to:
  /// **'İLERLEME: {percent}%'**
  String loadingProgress(String percent);

  /// No description provided for @loadingModelRunning.
  ///
  /// In tr, this message translates to:
  /// **'DİFÜZYON MODELİ ÇALIŞIYOR'**
  String get loadingModelRunning;

  /// No description provided for @loadingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kıyafet giydiriliyor •'**
  String get loadingTitle;

  /// No description provided for @loadingEta.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini süre ~40 sn'**
  String get loadingEta;

  /// No description provided for @loadingFinalTouches.
  ///
  /// In tr, this message translates to:
  /// **'Son rötuşlar...'**
  String get loadingFinalTouches;

  /// No description provided for @loadingProcessing.
  ///
  /// In tr, this message translates to:
  /// **'İşleniyor...'**
  String get loadingProcessing;

  /// No description provided for @loadingStepMask.
  ///
  /// In tr, this message translates to:
  /// **'Vücut Maskesi'**
  String get loadingStepMask;

  /// No description provided for @loadingStepMaskDesc.
  ///
  /// In tr, this message translates to:
  /// **'DensePose + SCHP ile giydirilecek bölge bulunur'**
  String get loadingStepMaskDesc;

  /// No description provided for @loadingStepDiffusion.
  ///
  /// In tr, this message translates to:
  /// **'Difüzyon (30 adım)'**
  String get loadingStepDiffusion;

  /// No description provided for @loadingStepDiffusionDesc.
  ///
  /// In tr, this message translates to:
  /// **'CatVTON kıyafeti kişinin üzerine çizer'**
  String get loadingStepDiffusionDesc;

  /// No description provided for @loadingStepBlend.
  ///
  /// In tr, this message translates to:
  /// **'Birleştirme'**
  String get loadingStepBlend;

  /// No description provided for @loadingStepBlendDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yüz ve arka plan orijinal fotoğraftan korunur'**
  String get loadingStepBlendDesc;

  /// No description provided for @statusDone.
  ///
  /// In tr, this message translates to:
  /// **'TAMAM'**
  String get statusDone;

  /// No description provided for @statusProcessing.
  ///
  /// In tr, this message translates to:
  /// **'İŞLENİYOR'**
  String get statusProcessing;

  /// No description provided for @statusQueued.
  ///
  /// In tr, this message translates to:
  /// **'SIRADA'**
  String get statusQueued;

  /// No description provided for @loadingCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get loadingCancel;

  /// No description provided for @loadingFailed.
  ///
  /// In tr, this message translates to:
  /// **'Giydirme işlemi başarısız: {reason}'**
  String loadingFailed(String reason);

  /// No description provided for @errorTimeout.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu çok uzun süre yanıt vermedi. Lütfen tekrar deneyin.'**
  String get errorTimeout;

  /// No description provided for @errorBackendOffline.
  ///
  /// In tr, this message translates to:
  /// **'Yapay zeka sunucusuna ulaşılamıyor. Backend açık mı?'**
  String get errorBackendOffline;

  /// No description provided for @errorServer.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu hatası ({code})'**
  String errorServer(String code);

  /// No description provided for @resultTitle.
  ///
  /// In tr, this message translates to:
  /// **'{category} Sonucu'**
  String resultTitle(String category);

  /// No description provided for @resultOverline.
  ///
  /// In tr, this message translates to:
  /// **'STÜDYO KARŞILAŞTIRMA'**
  String get resultOverline;

  /// No description provided for @resultHeading.
  ///
  /// In tr, this message translates to:
  /// **'Kombin Sonucu'**
  String get resultHeading;

  /// No description provided for @resultSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sanal giydirme sonucunu inceleyin ve detayları karşılaştırın.'**
  String get resultSubtitle;

  /// No description provided for @resultTabSplit.
  ///
  /// In tr, this message translates to:
  /// **'Sürgü'**
  String get resultTabSplit;

  /// No description provided for @resultTabSide.
  ///
  /// In tr, this message translates to:
  /// **'Yan Yana'**
  String get resultTabSide;

  /// No description provided for @resultTabFade.
  ///
  /// In tr, this message translates to:
  /// **'Geçiş'**
  String get resultTabFade;

  /// No description provided for @resultBefore.
  ///
  /// In tr, this message translates to:
  /// **'• ÖNCE'**
  String get resultBefore;

  /// No description provided for @resultAfter.
  ///
  /// In tr, this message translates to:
  /// **'✨ SONRA'**
  String get resultAfter;

  /// No description provided for @resultFullScreen.
  ///
  /// In tr, this message translates to:
  /// **'Tam Ekran'**
  String get resultFullScreen;

  /// No description provided for @resultSaveToGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeriye kaydet'**
  String get resultSaveToGallery;

  /// No description provided for @resultDetails.
  ///
  /// In tr, this message translates to:
  /// **'İşlem Detayları'**
  String get resultDetails;

  /// No description provided for @resultEngine.
  ///
  /// In tr, this message translates to:
  /// **'CatVTON • Yerel GPU'**
  String get resultEngine;

  /// No description provided for @resultRenderTime.
  ///
  /// In tr, this message translates to:
  /// **'İşlem Süresi'**
  String get resultRenderTime;

  /// No description provided for @resultSeconds.
  ///
  /// In tr, this message translates to:
  /// **'{seconds} sn'**
  String resultSeconds(String seconds);

  /// No description provided for @resultRenderTimeDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yerel ekran kartında ölçülen süre'**
  String get resultRenderTimeDesc;

  /// No description provided for @resultCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get resultCategory;

  /// No description provided for @resultCategoryDesc.
  ///
  /// In tr, this message translates to:
  /// **'Modelin giydirdiği bölge'**
  String get resultCategoryDesc;

  /// No description provided for @resultSaving.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get resultSaving;

  /// No description provided for @resultAddToWardrobe.
  ///
  /// In tr, this message translates to:
  /// **'Onayla ve Gardıroba Ekle'**
  String get resultAddToWardrobe;

  /// No description provided for @resultNeedLogin.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen önce giriş yapın.'**
  String get resultNeedLogin;

  /// No description provided for @resultWardrobeSaved.
  ///
  /// In tr, this message translates to:
  /// **'✨ Kombin gardırobuna başarıyla eklendi!'**
  String get resultWardrobeSaved;

  /// No description provided for @resultWardrobeError.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilirken hata oluştu: {reason}'**
  String resultWardrobeError(String reason);

  /// No description provided for @resultGallerySaved.
  ///
  /// In tr, this message translates to:
  /// **'Görsel galeriye kaydedildi.'**
  String get resultGallerySaved;

  /// No description provided for @resultGalleryWeb.
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcıda galeri yok; Paylaş butonunu ya da tam ekranda sağ tık → kaydet kullanın.'**
  String get resultGalleryWeb;

  /// No description provided for @resultGalleryFailed.
  ///
  /// In tr, this message translates to:
  /// **'Görsel kaydedilemedi.'**
  String get resultGalleryFailed;

  /// No description provided for @resultShareText.
  ///
  /// In tr, this message translates to:
  /// **'SeeItOn ile oluşturduğum yapay zeka destekli sanal kombinimi incele! ✨ #SeeItOn #SanalKabin'**
  String get resultShareText;

  /// No description provided for @wardrobeTitle.
  ///
  /// In tr, this message translates to:
  /// **'GARDIROBUM'**
  String get wardrobeTitle;

  /// No description provided for @wardrobeCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Henüz kombin yok} other{{count} kayıtlı kombin}}'**
  String wardrobeCount(int count);

  /// No description provided for @wardrobeDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days, plural, =0{Bugün} =1{Dün} other{{days} gün önce}}'**
  String wardrobeDaysAgo(int days);

  /// No description provided for @wardrobeEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gardırobun boş'**
  String get wardrobeEmptyTitle;

  /// No description provided for @wardrobeEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Bir kombin dene, sonuç ekranında \"Gardıroba Ekle\"ye bas; burada görünsün.'**
  String get wardrobeEmptyBody;

  /// No description provided for @wardrobeEmptyCta.
  ///
  /// In tr, this message translates to:
  /// **'Kombin Dene'**
  String get wardrobeEmptyCta;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya şifre hatalı.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailTaken.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-posta adresiyle zaten bir hesap var. Giriş yapmayı dene.'**
  String get authErrorEmailTaken;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi gir.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorNetwork.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok ya da sunucuya ulaşılamıyor.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorPasswordTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı.'**
  String get authErrorPasswordTooShort;

  /// No description provided for @loginShowPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi göster'**
  String get loginShowPassword;

  /// No description provided for @loginHidePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi gizle'**
  String get loginHidePassword;

  /// No description provided for @settingsAccount.
  ///
  /// In tr, this message translates to:
  /// **'HESAP'**
  String get settingsAccount;

  /// No description provided for @settingsSignedInAs.
  ///
  /// In tr, this message translates to:
  /// **'{email} olarak giriş yapıldı'**
  String settingsSignedInAs(String email);

  /// No description provided for @settingsSignOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get settingsSignOut;

  /// No description provided for @authErrorRateLimit.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar dene.'**
  String get authErrorRateLimit;

  /// No description provided for @wardrobeHeading.
  ///
  /// In tr, this message translates to:
  /// **'Kombinlerin'**
  String get wardrobeHeading;

  /// No description provided for @wardrobeFilterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get wardrobeFilterAll;

  /// No description provided for @wardrobeSignInTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gardırobun seni bekliyor'**
  String get wardrobeSignInTitle;

  /// No description provided for @wardrobeSignInBody.
  ///
  /// In tr, this message translates to:
  /// **'Denediğin kombinleri kaydetmek ve burada görmek için giriş yap.'**
  String get wardrobeSignInBody;

  /// No description provided for @wardrobeLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Gardırop yüklenemedi. İnternet bağlantını kontrol et.'**
  String get wardrobeLoadError;

  /// No description provided for @wardrobeRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get wardrobeRetry;

  /// No description provided for @wardrobeShare.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get wardrobeShare;

  /// No description provided for @wardrobeDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get wardrobeDelete;

  /// No description provided for @wardrobeDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kombin silinsin mi?'**
  String get wardrobeDeleteTitle;

  /// No description provided for @wardrobeDeleteBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu kombin gardırobundan kalıcı olarak silinecek.'**
  String get wardrobeDeleteBody;

  /// No description provided for @wardrobeDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get wardrobeDeleteConfirm;

  /// No description provided for @wardrobeCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get wardrobeCancel;

  /// No description provided for @wardrobeDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Kombin silindi.'**
  String get wardrobeDeleted;

  /// No description provided for @wardrobeDeleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kombin silinemedi. Tekrar dene.'**
  String get wardrobeDeleteFailed;

  /// No description provided for @wardrobeShareFailed.
  ///
  /// In tr, this message translates to:
  /// **'Görsel paylaşılamadı.'**
  String get wardrobeShareFailed;

  /// No description provided for @settingsAppearance.
  ///
  /// In tr, this message translates to:
  /// **'GÖRÜNÜM'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get settingsThemeDark;
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
