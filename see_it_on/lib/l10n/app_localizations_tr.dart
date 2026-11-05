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

  @override
  String get categoryBadgeUpper => 'ÜST GİYİM';

  @override
  String get categoryBadgeLower => 'ALT GİYİM';

  @override
  String get categoryBadgeOverall => 'TAM KIYAFET';

  @override
  String get loadingEngine => 'CATVTON • YEREL GPU';

  @override
  String loadingProgress(String percent) {
    return 'İLERLEME: $percent%';
  }

  @override
  String get loadingModelRunning => 'DİFÜZYON MODELİ ÇALIŞIYOR';

  @override
  String get loadingTitle => 'Kıyafet giydiriliyor •';

  @override
  String get loadingEta => 'Tahmini süre ~40 sn';

  @override
  String get loadingFinalTouches => 'Son rötuşlar...';

  @override
  String get loadingProcessing => 'İşleniyor...';

  @override
  String get loadingStepMask => 'Vücut Maskesi';

  @override
  String get loadingStepMaskDesc =>
      'DensePose + SCHP ile giydirilecek bölge bulunur';

  @override
  String get loadingStepDiffusion => 'Difüzyon (30 adım)';

  @override
  String get loadingStepDiffusionDesc =>
      'CatVTON kıyafeti kişinin üzerine çizer';

  @override
  String get loadingStepBlend => 'Birleştirme';

  @override
  String get loadingStepBlendDesc =>
      'Yüz ve arka plan orijinal fotoğraftan korunur';

  @override
  String get statusDone => 'TAMAM';

  @override
  String get statusProcessing => 'İŞLENİYOR';

  @override
  String get statusQueued => 'SIRADA';

  @override
  String get loadingCancel => 'İptal';

  @override
  String loadingFailed(String reason) {
    return 'Giydirme işlemi başarısız: $reason';
  }

  @override
  String get errorTimeout =>
      'Sunucu çok uzun süre yanıt vermedi. Lütfen tekrar deneyin.';

  @override
  String get errorBackendOffline =>
      'Yapay zeka sunucusuna ulaşılamıyor. Backend açık mı?';

  @override
  String errorServer(String code) {
    return 'Sunucu hatası ($code)';
  }

  @override
  String resultTitle(String category) {
    return '$category Sonucu';
  }

  @override
  String get resultOverline => 'STÜDYO KARŞILAŞTIRMA';

  @override
  String get resultHeading => 'Kombin Sonucu';

  @override
  String get resultSubtitle =>
      'Sanal giydirme sonucunu inceleyin ve detayları karşılaştırın.';

  @override
  String get resultTabSplit => 'Sürgü';

  @override
  String get resultTabSide => 'Yan Yana';

  @override
  String get resultTabFade => 'Geçiş';

  @override
  String get resultBefore => '• ÖNCE';

  @override
  String get resultAfter => '✨ SONRA';

  @override
  String get resultFullScreen => 'Tam Ekran';

  @override
  String get resultSaveToGallery => 'Galeriye kaydet';

  @override
  String get resultDetails => 'İşlem Detayları';

  @override
  String get resultEngine => 'CatVTON • Yerel GPU';

  @override
  String get resultRenderTime => 'İşlem Süresi';

  @override
  String resultSeconds(String seconds) {
    return '$seconds sn';
  }

  @override
  String get resultRenderTimeDesc => 'Yerel ekran kartında ölçülen süre';

  @override
  String get resultCategory => 'Kategori';

  @override
  String get resultCategoryDesc => 'Modelin giydirdiği bölge';

  @override
  String get resultSaving => 'Kaydediliyor...';

  @override
  String get resultAddToWardrobe => 'Onayla ve Gardıroba Ekle';

  @override
  String get resultNeedLogin => 'Lütfen önce giriş yapın.';

  @override
  String get resultWardrobeSaved => '✨ Kombin gardırobuna başarıyla eklendi!';

  @override
  String resultWardrobeError(String reason) {
    return 'Kaydedilirken hata oluştu: $reason';
  }

  @override
  String get resultGallerySaved => 'Görsel galeriye kaydedildi.';

  @override
  String get resultGalleryWeb =>
      'Tarayıcıda galeri yok; Paylaş butonunu ya da tam ekranda sağ tık → kaydet kullanın.';

  @override
  String get resultGalleryFailed => 'Görsel kaydedilemedi.';

  @override
  String get resultShareText =>
      'SeeItOn ile oluşturduğum yapay zeka destekli sanal kombinimi incele! ✨ #SeeItOn #SanalKabin';

  @override
  String get wardrobeTitle => 'GARDIROBUM';

  @override
  String wardrobeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kayıtlı kombin',
      zero: 'Henüz kombin yok',
    );
    return '$_temp0';
  }

  @override
  String wardrobeDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün önce',
      one: 'Dün',
      zero: 'Bugün',
    );
    return '$_temp0';
  }

  @override
  String get wardrobeEmptyTitle => 'Gardırobun boş';

  @override
  String get wardrobeEmptyBody =>
      'Bir kombin dene, sonuç ekranında \"Gardıroba Ekle\"ye bas; burada görünsün.';

  @override
  String get wardrobeEmptyCta => 'Kombin Dene';

  @override
  String get authErrorInvalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get authErrorEmailTaken =>
      'Bu e-posta adresiyle zaten bir hesap var. Giriş yapmayı dene.';

  @override
  String get authErrorWeakPassword => 'Şifre en az 6 karakter olmalı.';

  @override
  String get authErrorInvalidEmail => 'Geçerli bir e-posta adresi gir.';

  @override
  String get authErrorNetwork =>
      'İnternet bağlantısı yok ya da sunucuya ulaşılamıyor.';

  @override
  String get authErrorPasswordTooShort => 'Şifre en az 6 karakter olmalı.';

  @override
  String get loginShowPassword => 'Şifreyi göster';

  @override
  String get loginHidePassword => 'Şifreyi gizle';

  @override
  String get settingsAccount => 'HESAP';

  @override
  String settingsSignedInAs(String email) {
    return '$email olarak giriş yapıldı';
  }

  @override
  String get settingsSignOut => 'Çıkış yap';

  @override
  String get authErrorRateLimit =>
      'Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar dene.';

  @override
  String get wardrobeHeading => 'Kombinlerin';

  @override
  String get wardrobeFilterAll => 'Tümü';

  @override
  String get wardrobeSignInTitle => 'Gardırobun seni bekliyor';

  @override
  String get wardrobeSignInBody =>
      'Denediğin kombinleri kaydetmek ve burada görmek için giriş yap.';

  @override
  String get wardrobeLoadError =>
      'Gardırop yüklenemedi. İnternet bağlantını kontrol et.';

  @override
  String get wardrobeRetry => 'Tekrar dene';

  @override
  String get wardrobeShare => 'Paylaş';

  @override
  String get wardrobeDelete => 'Sil';

  @override
  String get wardrobeDeleteTitle => 'Kombin silinsin mi?';

  @override
  String get wardrobeDeleteBody =>
      'Bu kombin gardırobundan kalıcı olarak silinecek.';

  @override
  String get wardrobeDeleteConfirm => 'Sil';

  @override
  String get wardrobeCancel => 'Vazgeç';

  @override
  String get wardrobeDeleted => 'Kombin silindi.';

  @override
  String get wardrobeDeleteFailed => 'Kombin silinemedi. Tekrar dene.';

  @override
  String get wardrobeShareFailed => 'Görsel paylaşılamadı.';

  @override
  String get settingsAppearance => 'GÖRÜNÜM';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get onboardingIssue => 'No. 01 — Sanal Kabin';

  @override
  String get onboardingCoverLine2 => 'Yerel yapay zeka';

  @override
  String get onboardingCoverLine3 => 'Türkçe & English';

  @override
  String resultCaption(String category, String seconds) {
    return '$category — $seconds sn, yerel GPU';
  }

  @override
  String get cameraHint => 'Tam boy görün, kollar hafif açık';

  @override
  String get cameraUse => 'Kullan';

  @override
  String get cameraRetake => 'Tekrar çek';

  @override
  String get cameraSwitch => 'Kamerayı değiştir';

  @override
  String get cameraDenied => 'Kamera izni verilmedi.';

  @override
  String get cameraUnavailable => 'Bu cihazda kamera bulunamadı.';

  @override
  String get cameraUseGallery => 'Galeriden seç';

  @override
  String get cameraCapture => 'Fotoğraf çek';

  @override
  String get cameraClose => 'Kapat';
}
