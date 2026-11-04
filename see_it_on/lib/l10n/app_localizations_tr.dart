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

  @override
  String get homeSubtitle => 'Kendi stilini saniyeler içinde oluştur.';

  @override
  String get homeWhatToTry => 'NE DENEMEK İSTİYORSUN?';

  @override
  String get categoryUpper => 'Üst Giyim';

  @override
  String get categoryLower => 'Alt Giyim';

  @override
  String get categoryOverall => 'Tam Kıyafet';

  @override
  String get categoryUpperHint =>
      'Tişört, gömlek, kazak, ceket\nveya hırka fotoğrafı';

  @override
  String get categoryLowerHint =>
      'Pantolon, etek veya şort fotoğrafı. Şort/kısa etek için\nüzerinde kısa kıyafet olan bir fotoğraf daha iyi sonuç verir';

  @override
  String get categoryOverallHint =>
      'Elbise veya tulum\nfotoğrafı (tam boy kişi fotoğrafı önerilir)';

  @override
  String get homeStepPerson => 'ADIM 1  •  Kendi Fotoğrafın';

  @override
  String homeStepGarment(String category) {
    return 'ADIM 2  •  $category';
  }

  @override
  String get homeUploadPhoto => 'Fotoğraf Yükle';

  @override
  String get homeUploadPhotoHint =>
      'Net bir boy aynası selfie\'si\nveya düz durduğunuz bir fotoğraf';

  @override
  String get homeUploadGarment => 'Kıyafet Yükle';

  @override
  String get homeGallery => 'Galeri';

  @override
  String get homeCamera => 'Kamera';

  @override
  String get homeMannequin => 'Manken';

  @override
  String get homeSample => 'Örnek';

  @override
  String get homeTryOn => 'Üzerimde Gör';

  @override
  String get homeTryOnBadge => 'Try On';

  @override
  String get homeNeedPerson =>
      'Lütfen önce kendi fotoğrafınızı (Adım 1) yükleyin!';

  @override
  String get homeNeedGarment =>
      'Lütfen denemek istediğiniz kıyafeti (Adım 2) seçin!';

  @override
  String get homeRackTitle => 'ÖRNEK KIYAFET RAFI';

  @override
  String get homeRackSelect => 'BU PARÇAYI SEÇ';

  @override
  String homeRackSelected(String garment) {
    return '$garment seçildi. Şimdi fotoğrafını ekle ve \"Üzerimde Gör\"e bas.';
  }

  @override
  String homeSamplePickerTitle(String category) {
    return 'Örnek $category';
  }

  @override
  String get homeMannequinPickerTitle => 'Hazır Manken Seç';

  @override
  String get homeMannequinPickerHint =>
      'Kendi fotoğrafın yerine bir bedeni seçerek dene.';

  @override
  String get navTryOn => 'DENE';

  @override
  String get navWardrobe => 'GARDIROP';

  @override
  String get navProfile => 'PROFİL';

  @override
  String mannequinWomen(String size) {
    return 'Kadın $size';
  }

  @override
  String mannequinMen(String size) {
    return 'Erkek $size';
  }

  @override
  String get garmentBlazer => 'Ekose Blazer';

  @override
  String get garmentJeans => 'Mavi Kot';

  @override
  String get garmentChino => 'Bej Chino';

  @override
  String get garmentTrousers => 'Lacivert Pantolon';

  @override
  String get garmentSkirt => 'Pliseli Etek';

  @override
  String get garmentShorts => 'Kot Şort';
}
