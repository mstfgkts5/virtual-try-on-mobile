# 360° Dönüş Denemesi (Spin Try-On) — Tasarım

## Amaç ve neden
Sunumda jüriye "kıyafeti her açıdan görebiliyorum" etkisini göstermek. Kişi ayakları sabit, kendi etrafında tam tur dönüyormuş gibi görünür ve parmakla döndürülür. Gerçek 3D değil: bir dönüş videosundan alınan kareler tek tek giydirilir ve sırayla gösterilir. Gerçek 3D (SV3D, TripoSR vb.) 8 GB VRAM'e sığmadığı ve yüz/desen kalitesi düşük olduğu için kapsam dışı (ROADMAP, KNOWN_LIMITATIONS).

İki kaynak:
1. **Kendi videon:** kullanıcı telefonla çektiği 10–20 sn'lik dönüş videosunu seçer; backend kareleri çıkarıp giydirir.
2. **Hazır sunum seti:** önceden üretilmiş kareler uygulamanın içinde gelir; sahnede beklemeden anında açılır.

## Hedefler
- Video + kıyafet ön görseli (+ isteğe bağlı arka görsel) → 8 giydirilmiş kare.
- Kareler hazır oldukça ekranda belirir; ilk kare ~45 sn'de görünür, tamamı ~6 dk.
- Parmakla sürükleyerek döndürme, kareler arası yumuşak geçiş, "Döndür" düğmesiyle kendiliğinden tam tur.
- Hazır set aynı görüntüleyicide, backend olmadan açılır.
- Web (iPhone Safari) ve yerel derlemede aynı çalışır; TR/EN; açık/koyu tema.

## Hedef dışı
- Gerçek 3D model, video olarak oynatma (akıcı 24 fps), kareler arası titremeyi tamamen gidermek.
- Uygulama içinden video kaydetme (kullanıcı telefonun kamera uygulamasıyla çeker, galeriden seçer).
- Dönüşü gardıroba kaydetmek (yalnızca tek kare sonuç kaydı mevcut akışta kalır).
- Alt giyim ve tam kıyafet için arka görünüm doğruluğu garantisi; ilk sürüm üst giyimle denenir, kategori seçimi yine çalışır.

## Asla olmaması gerekenler (anti-hedefler)
- Sunumda donup kalan ekran: ilerleme her zaman görünür, kullanıcı her an çıkabilir.
- GPU'yu kilitli bırakan iş: ekrandan çıkınca iş iptal edilir; tek kare denemesi (`/api/v1/tryon`) spin işi sürerken sırada bekler ama kaybolmaz.
- Kişisel videonun diske kalıcı yazılması: kareler bellekte işlenir, geçici dosya iş bitince silinir.

## Kısıtlar
- Tek GPU (RTX 5060 Laptop, 8 GB). CatVTON kare başına ~43–50 sn, 30 adım. Mevcut `CatVTONEngine` tek kilitle istekleri sıraya koyuyor; spin aynı kilidi kullanır.
- Backend tek süreç (uvicorn). İşler bellekte tutulur; yeniden başlatınca kaybolur (kabul edilebilir).
- Flutter web'de videodan kare almak güvenilir değil → kareler backend'de çıkarılır.
- Yerel ağ HTTP üzerinden çalışılıyor; büyük gövde: video sınırı 60 MB, en fazla 30 sn.

## Yaklaşımlar
- **A) Video backend'de işlenir — SEÇİLDİ.** Uygulama videoyu ve kıyafet görsellerini tek istekle yollar; backend kareleri çıkarır, arka kareleri tanır, sırayla giydirir, iş numarası döner; uygulama durumu sorar ve hazır kareleri gösterir. Web ve telefonda aynı; kare seçimi ve arka görünüm kararı tek yerde.
- **B) Kareler uygulamada çıkarılır**, mevcut `/tryon` 8 kez çağrılır. Web'de güvenilir değil, ffmpeg paketi uygulamayı büyütür. Reddedildi.
- **Hazır set** her iki yolda aynı: paketlenmiş kareler, aynı görüntüleyici.

Kullanıcı A'yı seçti.

## Tasarım

### Backend (FastAPI, `backend/`)
- `POST /api/v1/spin` (multipart): `video` (zorunlu), `garment_front` (zorunlu), `garment_back` (isteğe bağlı), `category` (upper/lower/overall, varsayılan upper), `frames` (varsayılan 8, 4–12 arası). Yanıt: `{"job_id": "...", "total": 8}`. Doğrulama hataları 400 + anlaşılır `detail`.
- `GET /api/v1/spin/{job_id}?since=<n>`: `{"status": "queued|running|done|failed|cancelled", "total": 8, "done": 3, "frames": [{"index": 0, "view": "front|back", "image_base64": "...", "render_time": 44.1}], "error": null}`. `since` verilirse yalnızca `index >= since` olan hazır kareler döner (yük küçük kalır).
- `DELETE /api/v1/spin/{job_id}`: işi iptal eder; o anki kare biter, sıradakiler yapılmaz.
- **Kare çıkarma — kurucu kararı:** **PyAV** (`av` paketi, kendi ffmpeg'ini içerir) ile. iPhone varsayılan olarak HEVC `.MOV` kaydeder; Windows'taki OpenCV bunu çoğu zaman açamaz ve döndürme bilgisini uygulamayabilir. PyAV ile videonun ilk ve son %5'i atlanır, kalan süreden `frames` adet eşit aralıklı kare alınır, döndürme bilgisi uygulanır (dikey video dikey kalır), kare 3:4'e ortadan kırpılır. Video açılamazsa veya kare sayısı çıkarılamazsa 400 + "videoyu MP4/H.264 olarak kaydedin (iPhone: Ayarlar → Kamera → Formatlar → En Uyumlu)" ipucu.
- **Arka kare tanıma:** her karede `AutoMasker`'ın SCHP çıktısından yüz pikseli oranı ölçülür; eşiğin altındaysa kare "back". Arka görsel verildiyse arka karelerde o kullanılır, verilmediyse ön görsel kullanılır (sonuç yanıtında `view` yine bildirilir).
- **İş yürütme:** tek arka plan iş parçacığı, işler FIFO sırada; her kare `CatVTONEngine` kilidini ayrı alır, böylece araya gelen tek kare denemesi en fazla bir kare bekler. Bitmiş işler 30 dk sonra bellekten silinir.
- **Sahipsiz iş (kalp atışı) — kurucu kararı:** uygulama 3 sn'de bir durum sorar; bir iş için **30 sn boyunca hiç GET gelmezse** iş iptal edilir (Safari sekmesi kapandı, telefon kilitlendi, Wi-Fi koptu → DELETE gelmez). Ayrıca tek bir işin toplam süresi **15 dk** ile sınırlıdır. Sıradaki (henüz başlamamış) işler de aynı kurala tabidir. O anda işlenen kare yarıda kesilmediği için GPU en kötü durumda kalp atışı + bir kare (~80 sn) sonra boşalır (son inceleme kararı; KNOWN_LIMITATIONS 5).
- **Mevcut kod:** `engine.run` tek kare için aynen kullanılır; AutoMasker sonucuna (yüz oranı için) erişmek için küçük bir yardımcı eklenir.

### Uygulama (Flutter, `see_it_on/`)
- **Ana ekran, 1. adım:** yeni düğme **"Dönüş videosu"** (galeriden video seçer, `image_picker.pickVideo`). Video seçilince kartta videonun ilk karesi yerine bir video simgesi + süre ve "360° dönüş" etiketi görünür; fotoğraf seçilirse video temizlenir (ikisi birden olmaz).
- **2. adım:** video seçiliyken ön görselin yanında **"Arka görsel (isteğe bağlı)"** alanı belirir.
- **"Üzerimde Gör":** video varsa yeni `SpinScreen`'e gider; yoksa mevcut tek kare akışı.
- **Hazır set:** 1. adımın manken seçicisinde üstte **"Hazır 360° set"** kartı; seçilince doğrudan `SpinScreen` hazır karelerle açılır (backend çağrısı yok).
- **`SpinScreen`:** üstte `SpinViewer`, altında ilerleme ("3 / 8 kare hazır", ince ilerleme çizgisi, tahmini kalan süre), "Döndür" düğmesi. Ekrandan çıkınca iş iptal edilir (DELETE). Hata olursa mesaj + Geri. Durum 3 sn'de bir sorulur.
- **`SpinViewer(frames)`:** yatay sürükleme kare indeksini sürekli değiştirir (genişliğin tamamı ≈ tam tur); iki komşu kare arasında saydamlıkla geçiş; "Döndür" kendiliğinden tam turu ~4 sn'de oynatır; henüz hazır olmayan kareler atlanır. Kare sayısı 1 iken döndürme kapalıdır.
- **Tasarım:** mevcut belirteçler ve bileşenler (EditorialHeading, PillButton, SegmentedPills yok), TR/EN metinleri ARB'de.

### Hazır set
- `see_it_on/assets/images/spin/demo/frame_0.jpg … frame_7.jpg` + `manifest.json` (`{"title_tr", "title_en", "frames": 8}`).
- Üretim: `tools/make_spin_set.py <sıralı kişi görselleri klasörü> <ön> [--back arka] [--mirror]` → her görseli giydirir (arka görünümlerde arka görsel), `--mirror` ile yarım turun aynasını ekleyip tam tura tamamlar, 768×1024 JPEG olarak yazar.
- **İçerik bu işin parçası — kurucu kararı:** set 1 kişi + 1 kıyafetten oluşur. Kişi: denemedeki erkek manken (beyaz tişört, gri eşofman; RealVisXL dönüş sayfası, tohum 22). Açılar oradan elle seçilir: 3/4 ön, profil, 3/4 arka, arka (her biri ayrı ve temiz kırpılmış, `test_images/spin/` altında, git dışı); kalan yarım tur aynalanır → 7 kare. Kıyafet: önü ve arkası **aynı kumaşta** bir blazer çifti; birkaç tohumla üretilip en tutarlı çift seçilir. Son kareler kullanıcıya gösterilir, onayıyla `assets/`'e girer. Kare sayısı manifest'ten okunur (7 veya 8).

### Test
- Backend: kare örnekleme (süre, atlanan baş/son, sayı), arka kare eşiği, iş yaşam döngüsü (sıra, `since`, iptal, süre aşımı) sahte motorla `pytest`.
- Flutter: `SpinViewer` sürükleme → kare indeksi, 1 kare durumu; `SpinScreen` sahte servisle ilerleme, hata, çıkışta iptal; ana ekranda video/fotoğraf karşılıklı temizleme; dar ekran taşma testleri.
- Elle: iPhone Safari'de gerçek dönüş videosuyla uçtan uca.

## Kullanıcının kararları
- Etki odaklı (sunum), "ayakları sabit, kendi etrafında tam tur".
- Kaynak: video + hazır set.
- Yöntem: A (backend'de işleme).

## Kurucuya bırakılanlar
- Yüz oranı eşiğinin değeri (denemeyle seçilir), ilerleme çizgisinin görünümü, ARB metinlerinin tam ifadesi, iş temizleme zamanlayıcısının biçimi, kilit sırasının adil paylaşımı, 9:16 karelerin 768×1024 kırpılması, tohum seçimi.
