# SeeItOn — Dergi Tarzı Tasarım Sistemi ve Kamera Ekranı (Tasarım)

Tarih: 2026-11-05 · Durum: onay bekliyor

## Amaç ve neden
Proje açıklamasındaki "dergi tarzı (editorial) lüks tasarım, koyu/açık tema uyumu" vaadini gerçekten karşılamak ve kullanıcının başta en çok şikâyet ettiği tasarım eksikliğini gidermek. Ek olarak kullanıcı, AnyWear (Decart) benzeri "kamerayı aç, üzerinde gör" deneyimine yaklaşmak istiyor; bunun ilk adımı uygulama içi canlı kamera çekimi.

## Mevcut durum (envanter)
- 9 ekranda ~56 farklı renk tanımı, 31 farklı köşe yuvarlaklığı, 51 farklı yazı boyutu; ortak tema yok, renkler dosyalara gömülü.
- Tanıtım/giriş/ana/ayarlar/gardırop krem; **yükleme ve sonuç ekranları koyu siyah** (kopuk).
- Koyu mod yok. İkonlar karışık Material setlerinden.
- "Kamera" butonu sistem kamerasını açıyor (image_picker); iOS `Info.plist`'te `NSCameraUsageDescription` **eksik** → iPhone'da kamera açılınca uygulama kapanır.

## Kullanıcının kararları
- Dergi tarzı lüks tasarıma sadık kalınacak; Claude'un önerdiği değişiklikler yapılacak.
- Kamera: **1. yol** (uygulama içi akıllı çekim). İleride **2. yol** (canlı AR önizleme + HD yapay zeka çekimi) eklenebilecek şekilde tasarlanacak.

## Hedefler
### A. Tasarım sistemi (`lib/core/design/`)
- **Renk belirteçleri** (açık / koyu):
  | Belirteç | Açık | Koyu | Kullanım |
  |---|---|---|---|
  | paper | `#F6F3EE` | `#121110` | zemin |
  | surface | `#FFFFFF` (%70) | `#1C1A18` | kartlar |
  | ink | `#1E1C1A` | `#F3EFE7` | metin, birincil buton |
  | muted | `#8A847C` | `#A39C92` | ikincil metin |
  | line | `#E4DED3` | `#2E2B27` | ince ayırıcılar |
  | accent | `#7A2E3A` (bordo) | `#C9737F` | vurgu: seçili durum, "No. 01", bağlantılar |
  | danger | `#B42318` | `#F97066` | silme, hata |
- **Tipografi:** başlıklar **Playfair Display** (serif), metin **Inter**; yazı tipi dosyaları uygulamaya gömülür (OFL lisanslı, internetsiz çalışır). Ölçek: display 40, h1 32, h2 22, title 16, body 14, caption 12, overline 11 (büyük harf, harf aralığı 1.6 — büyük harf ARB'de yazılır, kodda `toUpperCase` yok).
- **Biçim:** köşe yuvarlaklığı yalnızca 3 değer (12 / 20 / 28) + hap (999); boşluk ölçeği 4-8-12-16-20-24-32-48.
- **Bileşenler** (`lib/core/design/widgets.dart`): `EditorialOverline`, `EditorialHeading`, `PillButton` (birincil/ikincil), `SegmentedPills` (kategori/dil/tema seçicileri tek bileşen), `HairlineDivider`, `EditorialCard`, `Caption`.
- **Tema modu:** Ayarlar'da **Görünüm: Sistem / Açık / Koyu**; seçim kalıcı (dil seçimindeki gibi `shared_preferences`).
- Tek ikon dili: Material Symbols **outlined** (Flutter'ın `Icons.*_outlined` varyantları).

### B. Ekranlar
- **Tanıtım = dergi kapağı:** büyük "SeeItOn" maskeleti (Playfair), "No. 01 — Sanal Kabin" künyesi, kapak fotoğrafı, 2-3 kapak satırı (Üst • Alt • Tam Kıyafet / Yerel yapay zeka / Türkçe & English).
- **Giriş:** aynı tipografi, ince çizgili alanlar, birincil hap buton.
- **Ana ekran:** başlık bloğu (overline + heading), adım kartları ve kategori seçicisi ortak bileşenlerle; raf korunur, tipografi güncellenir.
- **Yükleme:** koyu siyahtan çıkar; kâğıt zemin, ortada kişinin fotoğrafı yumuşak maske altında, adımlar dergi içindekiler listesi gibi (numaralı, ince çizgili).
- **Sonuç = dergi sayfası:** büyük görsel + altında italik açıklama ("Alt Giyim — 38,8 sn, yerel GPU"), karşılaştırma sekmeleri `SegmentedPills`, birincil "Gardıroba Ekle" + ikincil paylaş/kaydet.
- **Gardırop / detay / ayarlar:** ortak bileşenlere geçer; ayarlara Görünüm seçici eklenir.
- **Hareket:** ekran geçişleri yumuşak kayma + solma (tek bir `PageRoute` yardımcısı); mevcut Hero'lar korunur.
- Koyu modda tüm ekranlar belirteçlerden renk alır; sabit renk kalmaz (fotoğraf üstü beyaz rozetler gibi istisnalar hariç).

### C. Kamera ekranı (1. yol)
- `camera` paketi (Android, iOS, web). Yeni `lib/screens/camera_capture_screen.dart`:
  - Tam ekran canlı önizleme (3:4 kırpılmış), üstünde **tam boy silüet çerçevesi** ve kısa ipucu ("Tam boy görün, kollar hafif açık").
  - Ön/arka kamera değiştirme, **3-2-1 geri sayım**, deklanşör; çekilen kare önizlenir: **Kullan / Tekrar çek**.
  - "Kullan" → baytlar ana ekrandaki 1. adıma döner, mevcut CatVTON akışı değişmez.
  - İzin reddedilirse / kamera yoksa: açıklayıcı mesaj + galeriye yönlendirme.
- **2. yola hazırlık:** önizleme üstünde katman yuvası: `abstract class CameraOverlay { Widget build(context, CameraController); }` ve kare analizi için `abstract class FrameAnalyzer`. 1. yolda yalnızca `SilhouetteOverlay` uygulanır; AR'de `PoseOverlay` + ML Kit analizi bu yuvalara eklenecek (yalnız Android/iOS).
- **Platform ayarları:** iOS `NSCameraUsageDescription` (+ galeri için `NSPhotoLibraryUsageDescription`), Android `CAMERA` izni.
- Ana ekrandaki "Kamera" butonu kişi fotoğrafı için bu ekranı açar; kıyafet fotoğrafı için sistem kamerası (image_picker) kalır.

## Kapsam dışı
- AR önizleme (2. yol), hızlı mod (adım sayısı düşürme), tablet düzeni, animasyonlu kapak videosu.

## Anti-hedefler
- Koyu modda okunmayan metin / beyaz zemin üstünde beyaz yazı.
- Tasarım değişikliğinin mevcut akışı bozması (deneme, kayıt, gardırop, dil değiştirme testleri geçmeye devam etmeli).
- 360 px genişlikte taşma.

## Yaklaşımlar
| Yaklaşım | Artı | Eksi |
|---|---|---|
| **1. Kendi belirteç + bileşen katmanımız, `ThemeData` + `ThemeExtension` (seçildi)** | Tüm ekranlar tek kaynaktan; koyu mod doğal; Flutter'ın standart yolu | Ekranların tek tek bileşenlere geçirilmesi gerekir |
| 2. Hazır tema paketi (flex_color_scheme vb.) | Hızlı başlangıç | Dergi tarzı özgün görünüm zor; paket bağımlılığı |
| 3. Yalnızca renkleri sabitlere toplamak | En az iş | Koyu mod ve tipografi tutarlılığı çözülmez |

## Test
- Belirteçler: açık/koyu tema `ThemeExtension` değerleri; `ThemeModeController` kalıcılığı (dil denetleyicisi testlerinin eşi).
- Her ekran açık + koyu temada 360 px genişlikte taşmasız açılır (`takeException` null).
- Kamera: izin reddi ve "kamera yok" durumları sahte `CameraService` ile; "Kullan" baytları geri döndürür.
- Mevcut 57 test geçmeye devam eder.

## Builder'a bırakılanlar (Claude'un kararları)
- Vurgu rengi bordo `#7A2E3A`; yazı tipleri Playfair Display + Inter.
- Yükleme ekranı da açık zeminde (koyu "karanlık oda" yerine tutarlılık).
- Kamera ekranında arka kamera varsayılan değil, **ön kamera** varsayılan (selfie ile tam boy çekim için telefon bir yere dayanır, 3 sn geri sayım bunun için).
