# Dergi Tarzı Tasarım Sistemi ve Kamera Ekranı — Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tüm ekranları tek bir dergi tarzı tasarım sistemine (açık + koyu) geçirmek ve kişi fotoğrafı için uygulama içi kamera ekranı eklemek.

**Architecture:** Renk/tipografi/biçim belirteçleri `ThemeExtension` (`SeeItOnTokens`) olarak açık ve koyu `ThemeData`'ya eklenir; ekranlar renkleri `context.tokens` üzerinden okur, ortak bileşenler `lib/core/design/widgets.dart`'tadır. Tema modu dil denetleyicisinin eşi olan `ThemeModeController` ile kalıcıdır. Kamera, `CameraService` soyutlaması arkasında `camera` paketini kullanır; önizleme üstünde `CameraOverlay` yuvası 2. yol (AR) için bırakılır.

**Tech Stack:** Flutter (SDK >=3.10), `camera`, `shared_preferences`, gen-l10n, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-11-05-editorial-design-and-camera.md`

## Global Constraints
- Komutlar `see_it_on/` içinden; Flutter: `C:\src\flutter\bin\flutter.bat`.
- Renkler (açık / koyu): paper `#F6F3EE`/`#121110`, surface `#FFFFFF`@0.7/`#1C1A18`, ink `#1E1C1A`/`#F3EFE7`, muted `#8A847C`/`#A39C92`, line `#E4DED3`/`#2E2B27`, accent `#7A2E3A`/`#C9737F`, danger `#B42318`/`#F97066`.
- Tipografi: başlık **Playfair Display**, metin **Inter**, dosyalar `assets/fonts/` altında gömülü (OFL). Ölçek: display 40, h1 32, h2 22, title 16, body 14, caption 12, overline 11 (harf aralığı 1.6). Büyük harf metinler ARB'de yazılır; `toUpperCase` yok.
- Köşe yarıçapı yalnızca 12 / 20 / 28 / 999; boşluk 4-8-12-16-20-24-32-48.
- İkonlar `Icons.*_outlined` varyantları (yoksa düz varyant).
- Ekranlarda sabit `Color(0x…)` kalmaz; istisna: fotoğraf üstü yarı saydam beyaz/siyah rozet ve gradyanlar.
- Yeni metinler TR+EN ARB'de. Her görev sonunda `flutter analyze` → No issues found!, `flutter test` → All tests passed!
- Tema modu `shared_preferences` anahtarı `app_theme_mode`, değerler `'system' | 'light' | 'dark'`.

## Review Focus
- Koyu modda fotoğraf olmayan her yüzeyde metin okunur olmalı (ink/paper zıtlığı). Her ekran görevinde "koyu temada 360 px taşmasız açılır" testi + tarayıcıda koyu mod ekran görüntüsü (Task 9).
- Kamera izni reddedilir ya da cihazda kamera yoktur (masaüstü web) → çökme yok, mesaj + "Galeriden seç". Task 8 testleri.
- Kamera ekranından geri dönülürse / uygulama arka plana alınırsa `CameraController` serbest bırakılır (siyah ekran veya kilitli kamera yok). Task 8: `dispose` sahte serviste `disposed == true`.
- Tema modu "Sistem"deyken cihaz koyuya geçerse uygulama da geçer. Task 1: `ThemeMode.system` MaterialApp'e verilir (test: controller değeri `ThemeMode.system`).
- Uzun İngilizce metinler yeni tipografide (Playfair daha geniş) 360 px'te taşmamalı. Task 4–7 testleri EN + 360 px.

---

### Task 1: Belirteçler, tema, yazı tipleri, tema modu

**Files:**
- Create: `lib/core/design/tokens.dart`, `lib/core/design/theme.dart`, `lib/core/theme_mode_controller.dart`
- Create: `assets/fonts/` (PlayfairDisplay Regular/Medium/SemiBold/Italic, Inter Regular/Medium/SemiBold — google/fonts deposundan statik TTF; statik yoksa değişken TTF ve ağırlık için `fontVariations`) + `assets/fonts/OFL.txt`
- Modify: `pubspec.yaml` (`fonts:` bölümü), `lib/main.dart`
- Test: `test/design_tokens_test.dart`, `test/theme_mode_controller_test.dart`

**Interfaces:**
- Produces: `class SeeItOnTokens extends ThemeExtension<SeeItOnTokens>` alanları `paper, surface, ink, muted, line, accent, danger` (Color); `static const light`, `static const dark`. `extension TokensX on BuildContext { SeeItOnTokens get tokens; }`.
- Produces: `ThemeData buildTheme(Brightness b)` — `extensions: [SeeItOnTokens.light|dark]`, `scaffoldBackgroundColor: paper`, `fontFamily: 'Inter'`, `textTheme` ölçeği (display/h1/h2 → `displaySmall/headlineLarge/headlineSmall` Playfair; title/body/caption → `titleMedium/bodyMedium/bodySmall` Inter; overline → `labelSmall` Inter 11, letterSpacing 1.6).
- Produces: `class ThemeModeController extends ValueNotifier<ThemeMode>`; `static Future<ThemeModeController> load({Future<SharedPreferences> Function() prefs})`; `Future<void> setMode(ThemeMode)`; global `late ThemeModeController themeModeController;` (dil denetleyicisiyle aynı desen, depolama hatasında `ThemeMode.system`).
- `SeeItOnApp`: `theme: buildTheme(light)`, `darkTheme: buildTheme(dark)`, `themeMode:` iki `ValueListenableBuilder` (dil + tema).

- [ ] **Step 1: Failing tests**
  - `açık/koyu belirteçler`: `SeeItOnTokens.light.accent == Color(0xFF7A2E3A)`, `.dark.paper == Color(0xFF121110)`, `buildTheme(Brightness.dark).extension<SeeItOnTokens>() == SeeItOnTokens.dark`
  - `başlık yazı tipi`: `buildTheme(light).textTheme.headlineLarge!.fontFamily == 'PlayfairDisplay'`, `.fontSize == 32`
  - `ThemeModeController`: varsayılan `system`; `{'app_theme_mode':'dark'}` → `dark`; bozuk `'blue'` → `system`; `setMode(light)` kalıcı; depolama hatası → `system`, çökme yok
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** Yazı tiplerini indir (OFL), pubspec `fonts:` ailelerini `PlayfairDisplay` ve `Inter` adlarıyla tanımla; dosyaları ve `main.dart` bağlantısını yaz.
- [ ] **Step 4:** PASS + analyze temiz (mevcut testler `SeeItOnApp` üzerinden geçtiği için `themeModeController` test kurulumlarında atanır)
- [ ] **Step 5:** Commit `feat(design): tokens, light/dark theme, bundled fonts, persistent theme mode`

### Task 2: Ortak bileşenler

**Files:**
- Create: `lib/core/design/widgets.dart`
- Test: `test/design_widgets_test.dart`

**Interfaces (hepsi renkleri `context.tokens`'tan alır):**
- `EditorialOverline(String text)` — labelSmall, muted
- `EditorialHeading(String text, {double size = 32})` — Playfair
- `Caption(String text, {bool italic = false})`
- `HairlineDivider()` — 1 px `line`
- `PillButton({required String label, required VoidCallback? onPressed, IconData? icon, bool primary = true, bool busy = false})` — birincil: ink zemin/paper yazı; ikincil: çerçeveli; `busy` → küçük gösterge
- `SegmentedPills<T>({required List<(T, String)> options, required T value, required ValueChanged<T> onChanged, Map<T, IconData>? icons})` — kategori/dil/tema seçicisi; eşit genişlik, etiket `Flexible`+ellipsis
- `EditorialCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(20)})` — surface zemin, yarıçap 28, ince `line` çerçeve
- `Future<T?> pushEditorial<T>(BuildContext, Widget)` — kayma + solma geçişi (`PageRouteBuilder`, 280 ms)

- [ ] **Step 1: Failing tests**
  - `SegmentedPills seçim bildirir`: 3 seçenek, ikinciye dokun → `onChanged('b')`
  - `bileşenler açık ve koyu temada 360 px'te taşmasız`: hepsini bir Column'da `buildTheme(dark)` ile 360×800'de çiz → `takeException()` null; aynısı light
  - `PillButton busy iken onPressed çağrılmaz`
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** Uygula.
- [ ] **Step 4:** PASS + analyze
- [ ] **Step 5:** Commit `feat(design): shared editorial widgets and page transition`

### Task 3: Ayarlar — Görünüm seçici, dil seçici ortak bileşende

**Files:**
- Modify: `lib/screens/settings_screen.dart`, ARB (`settingsAppearance` = "GÖRÜNÜM"/"APPEARANCE", `settingsThemeSystem` = "Sistem"/"System", `settingsThemeLight` = "Açık"/"Light", `settingsThemeDark` = "Koyu"/"Dark")
- Test: `test/settings_screen_test.dart`

- [ ] **Step 1: Failing test** `Koyu seçilince tema modu dark ve kalıcı`: `tap(find.text('Koyu'))` → `themeModeController.value == ThemeMode.dark`, prefs `'dark'`; ekran koyu temada yeniden çizilir (`Theme.of(context).brightness == Brightness.dark` olan bir widget bulunur)
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** `_LanguageSelector` yerine `SegmentedPills`; Görünüm bölümü dil bölümünün altına; hesap bölümü `PillButton` ve belirteç renkleri.
- [ ] **Step 4:** PASS (mevcut 4 ayarlar testi dahil) + analyze
- [ ] **Step 5:** Commit `feat(design): appearance setting (system/light/dark)`

### Task 4: Tanıtım (dergi kapağı) ve giriş

**Files:**
- Modify: `lib/screens/onboarding_screen.dart`, `lib/screens/login_screen.dart`, ARB (`onboardingIssue` = "No. 01 — Sanal Kabin"/"No. 01 — The Fitting Room", `onboardingCoverLine2` = "Yerel yapay zeka"/"Local AI", `onboardingCoverLine3` = "Türkçe & English")
- Test: `test/widget_test.dart` (+ `test/design_screens_test.dart` ortak taşma testi yardımcı fonksiyonu: `Future<void> expectNoOverflow(WidgetTester, Widget screen, {required String lang, required Brightness b})`)

- [ ] **Step 1: Failing tests:** `kapakta künye görünür` (`find.text(l.onboardingIssue)`); tanıtım ve giriş ekranları TR-açık, EN-koyu, 360×800 taşmasız
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** Kapak: üstte maskelet "SeeItOn" (Playfair 40), künye overline, kapak fotoğrafı yarıçap 28, altında `HairlineDivider` ile ayrılmış 3 kapak satırı, birincil `PillButton`. Giriş: `EditorialHeading`, alanlar surface zemin + `line` çerçeve, `PillButton`.
- [ ] **Step 4:** PASS + analyze
- [ ] **Step 5:** Commit `feat(design): magazine cover onboarding and restyled login`

### Task 5: Ana ekran

**Files:** Modify `lib/screens/home_screen.dart`; Test `test/home_screen_test.dart`

- [ ] **Step 1: Failing test:** ana ekran EN-koyu ve TR-açık 360×800 taşmasız (mevcut 375 EN testi korunur)
- [ ] **Step 2:** FAIL (koyu temada sabit renkler / yeni testin taşması — RED yoksa sabit renk taraması `grep -c "Color(0x" lib/screens/home_screen.dart` > 0 kanıt sayılır)
- [ ] **Step 3:** Başlık `EditorialOverline`+`EditorialHeading`; kategori seçici `SegmentedPills`; adım kartları `EditorialCard`; "Üzerimde Gör" `PillButton`; manken/kıyafet alt sayfaları belirteç renkleri; raf tipografisi; sabit renkler belirteçlere.
- [ ] **Step 4:** PASS + analyze; `grep -c "Color(0x" lib/screens/home_screen.dart` → 0
- [ ] **Step 5:** Commit `feat(design): home screen on design system`

### Task 6: Yükleme ve sonuç ekranları

**Files:** Modify `lib/screens/loading_screen.dart`, `lib/screens/result_screen.dart`, ARB (`resultCaption` = "{category} — {seconds} sn, yerel GPU" / "{category} — {seconds} s, local GPU"); Test `test/result_screen_test.dart`, `test/design_screens_test.dart`

- [ ] **Step 1: Failing tests:** sonuç ekranında `find.text(l.resultCaption('Alt Giyim', '40.0'))`; sonuç ekranı EN-koyu 360 taşmasız; yükleme ekranı (backend'e istek atmaması için `LoadingScreen`'e `ApiService? api` parametresi, testte sahte ApiService alt sınıfı asla tamamlanmayan Future döner) TR-açık 360 taşmasız
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** Yükleme: paper zemin, kişi fotoğrafı yarıçap 28 + yumuşak örtü, adımlar numaralı içindekiler listesi (`HairlineDivider`), ilerleme çizgisi accent. Sonuç: büyük görsel + italik `Caption`, sekmeler `SegmentedPills`, "Gardıroba Ekle" `PillButton(busy: _isSaving)`, paylaş/kaydet ikincil.
- [ ] **Step 4:** PASS (mevcut sonuç testleri dahil) + analyze; iki dosyada `Color(0x` sayısı yalnızca fotoğraf üstü istisnalar
- [ ] **Step 5:** Commit `feat(design): editorial loading and result screens`

### Task 7: Gardırop ve detay

**Files:** Modify `lib/screens/wardrobe_screen.dart`, `lib/screens/wardrobe_detail_screen.dart`; Test `test/wardrobe_screen_test.dart`

- [ ] **Step 1: Failing test:** kayıtlı liste EN-koyu 360 taşmasız (mevcut 9 gardırop testi korunur)
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** Dosya üstü `_bg/_ink/_dark` sabitleri kaldırılır → belirteçler; filtre düğmeleri `SegmentedPills` değil (sayılı, çok satırlı) mevcut `_FilterChip` belirteçlere geçer; mesaj butonları `PillButton`; detayda sil iletişim kutusu `danger`.
- [ ] **Step 4:** PASS + analyze
- [ ] **Step 5:** Commit `feat(design): wardrobe on design system`

### Task 8: Uygulama içi kamera

**Files:**
- Modify: `pubspec.yaml` (`camera`), `ios/Runner/Info.plist` (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`), `android/app/src/main/AndroidManifest.xml` (`android.permission.CAMERA`)
- Create: `lib/services/camera_service.dart`, `lib/screens/camera_capture_screen.dart`
- Modify: `lib/screens/home_screen.dart` (1. adım "Kamera" → `CameraCaptureScreen`, dönen baytlar `_personImageBytes`), ARB (`cameraHint` = "Tam boy görün, kollar hafif açık"/"Show your full body, arms slightly apart", `cameraUse` = "Kullan"/"Use photo", `cameraRetake` = "Tekrar çek"/"Retake", `cameraSwitch` = "Kamerayı değiştir"/"Switch camera", `cameraDenied` = "Kamera izni verilmedi."/"Camera permission was denied.", `cameraUnavailable` = "Bu cihazda kamera bulunamadı."/"No camera found on this device.", `cameraUseGallery` = "Galeriden seç"/"Choose from gallery")
- Test: `test/camera_capture_screen_test.dart`

**Interfaces:**
- `abstract class CameraService { Future<void> init({bool front = true}); Widget preview(); Future<Uint8List> capture(); Future<void> switchCamera(); Future<void> dispose(); bool get hasMultipleCameras; }` + `class PluginCameraService implements CameraService` (`camera` paketi; init hataları `CameraAccessDeniedException` / `NoCameraException` olarak çevrilir).
- `abstract class CameraOverlay { Widget build(BuildContext context); }`; `class SilhouetteOverlay implements CameraOverlay` (ince accent çizgili tam boy silüet + `cameraHint`). AR için ileride `PoseOverlay` + `FrameAnalyzer` eklenecek — bu görevde yalnızca `CameraOverlay` yuvası.
- `class CameraCaptureScreen extends StatefulWidget { const CameraCaptureScreen({CameraService? service, CameraOverlay overlay = const SilhouetteOverlay(), Duration countdown = const Duration(seconds: 3)}); }` — sonuç: `Navigator.pop<Uint8List>(bytes)`; "Galeriden seç" → `Navigator.pop` ile `null` ve ana ekran galeri seçiciyi açar (dönen değer `CameraResult.gallery` enum'u ile ayırt edilir: `pop<Object>(CameraResult.gallery)`).

- [ ] **Step 1: Failing tests** (sahte `FakeCameraService`; `countdown: Duration.zero`)
  - `izin reddi mesajı`: `init` → `CameraAccessDeniedException` → `find.text(l.cameraDenied)` ve `find.text(l.cameraUseGallery)`
  - `kamera yok mesajı`: `NoCameraException` → `l.cameraUnavailable`
  - `çek → önizle → kullan baytları döndürür`: deklanşöre bas → `find.text(l.cameraUse)` → bas → push sonucu sahte baytlara eşit
  - `tekrar çek önizlemeyi kapatır`
  - `geri dönülünce kamera serbest bırakılır`: pop sonrası `fake.disposed == true`
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** Platform izinleri, servis, ekran (tam ekran önizleme 3:4, üstte overlay, altta deklanşör + kamera değiştirme, geri sayım rakamı Playfair 96), ana ekran bağlantısı. `WidgetsBindingObserver` ile `paused` → `dispose`, `resumed` → `init`.
- [ ] **Step 4:** PASS + analyze
- [ ] **Step 5:** Commit `feat(camera): in-app capture screen with silhouette guide and AR-ready overlay slot`

### Task 9: Uçtan uca kontrol

- [ ] **Step 1:** `flutter analyze` temiz, `flutter test` geçer; `grep -rc "Color(0x" lib/screens` yalnızca fotoğraf üstü istisnalar.
- [ ] **Step 2: Tarayıcı** (backend + flutter web): açık temada tanıtım → giriş → ana → kamera (web kamerası; izin isteğini kullanıcı onaylar) → deneme → sonuç → gardırop; Ayarlar'dan Koyu → aynı ekranların ekran görüntüleri; EN + koyu bir tur.
- [ ] **Step 3:** ROADMAP güncelle, commit, push.
