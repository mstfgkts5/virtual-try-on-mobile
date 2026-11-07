# SeeItOn – Mimari

SeeItOn üç parçadan oluşur: telefonda (veya tarayıcıda) çalışan **Flutter uygulaması**, aynı ağdaki bilgisayarda yerel GPU ile çalışan **FastAPI + CatVTON backend'i** ve kimlik doğrulama ile gardırobu tutan **Supabase**. Sanal deneme internete çıkmadan, yerel GPU'da yapılır; yalnızca giriş ve gardırop Supabase'e gider.

## 1. Bileşenler

```mermaid
flowchart LR
    subgraph Phone["Telefon / tarayıcı — Flutter (TR/EN, açık/koyu)"]
        UI["Ekranlar<br/>tanıtım · giriş · ana · kamera<br/>yükleme · sonuç · 360° dönüş · gardırop · ayarlar"]
        API["ApiService<br/>(HTTP, çok parçalı yükleme)"]
        REPO["WardrobeRepository"]
        UI --> API
        UI --> REPO
    end

    subgraph PC["Bilgisayar — RTX 5060 Laptop, 8 GB (yerel ağ)"]
        FAST["FastAPI<br/>/api/v1/tryon · /api/v1/spin"]
        JOBS["SpinJobManager<br/>FIFO kuyruk · kalp atışı · iptal"]
        FRAMES["spin_frames<br/>PyAV kare çıkarma · arka kare tanıma"]
        ENG["CatVTONEngine<br/>15 adım · 576×768 · bf16"]
        MASK["AutoMasker<br/>DensePose + SCHP"]
        RIFE["RIFE<br/>ara kareler"]
        FAST --> JOBS
        FAST --> FRAMES
        JOBS --> ENG
        JOBS --> RIFE
        ENG --> MASK
    end

    subgraph Cloud["Supabase (bulut)"]
        AUTH["Auth<br/>e-posta / şifre"]
        DB[("wardrobe tablosu<br/>RLS")]
        ST[("wardrobe_images<br/>depolama")]
    end

    API -- "HTTP, yerel Wi-Fi / kişisel erişim noktası" --> FAST
    REPO --> AUTH
    REPO --> DB
    REPO --> ST
```

| Parça | Teknoloji | Görev |
|---|---|---|
| Uygulama | Flutter 3, gen-l10n, `supabase_flutter`, `camera`, `image_picker` | Arayüz, kamera/galeri, durum, iki dil, iki tema |
| Backend | Python, FastAPI, PyTorch | İstekleri doğrular, görselleri hazırlar, modeli çalıştırır |
| Model | CatVTON (SD 1.5 inpainting tabanlı), DensePose, SCHP | Kıyafeti kişinin üzerine çizer; vücut maskesini çıkarır |
| Ara kare | RIFE (ECCV 2022, MIT) | 360° dönüşte ana kareler arasını doldurur |
| Veri | Supabase Auth, Postgres (RLS), Storage | Hesap, gardırop kayıtları, sonuç görselleri |

## 2. Tek fotoğraf denemesi

İstek eşzamanlıdır: uygulama yanıtı bekler (ölçülen ~8–17 sn), bu sırada yükleme ekranı tahmini ilerleme gösterir.

```mermaid
sequenceDiagram
    actor U as Kullanıcı
    participant App as Flutter (LoadingScreen)
    participant API as FastAPI
    participant E as CatVTONEngine (GPU)

    U->>App: Kişi + kıyafet + kategori seç, "Üzerimde Gör"
    App->>API: POST /api/v1/tryon (person_image, garment_image, category, steps=15)
    API->>API: Doğrula (boyut ≤15 MB, kategori, adım 10–50)
    API->>E: run(kişi, kıyafet, kategori)
    E->>E: EXIF düzelt, 576×768 kırp
    E->>E: AutoMasker: DensePose + SCHP → kıyafet maskesi
    E->>E: 15 adım difüzyon (rehberlik 2,5)
    E->>E: Maske dışını orijinalden geri al (kenar izi yok)
    E-->>API: sonuç + kırpılmış kişi + süre
    API-->>App: 200 {image_base64, person_base64, category, render_time}
    App->>U: Sonuç ekranı (sürgü · yan yana · geçiş karşılaştırma)
```

## 3. 360° dönüş

Uzun süren iş: backend bir iş numarası döner, uygulama 3 sn'de bir sorar ve hazır kareleri geldikçe gösterir.

```mermaid
sequenceDiagram
    actor U as Kullanıcı
    participant App as Flutter (SpinScreen)
    participant API as FastAPI
    participant F as spin_frames
    participant J as SpinJobManager
    participant E as CatVTON + RIFE (GPU)

    U->>App: Dönüş videosu + kıyafet ön (+ arka) görseli
    App->>API: POST /api/v1/spin (video, garment_front, garment_back?, frames=12)
    API->>F: extract_frames(video, 12)
    F-->>API: 12 dikey kare (döndürme bilgisi uygulanmış)
    API->>J: submit(kareler, ön, arka)
    API-->>App: {job_id, total: 48}
    loop Her ana kare k (arka plan iş parçacığı)
        J->>E: is_back_view(kare) — yüz oranı < 0,015 ise arka
        J->>E: run(kare, ön veya arka kıyafet)
        J->>E: interpolate(k−1, k) → 3 ara kare
    end
    J->>E: interpolate(son, ilk) → turu kapatan 3 ara kare
    loop 3 sn'de bir (kalp atışı)
        App->>API: GET /api/v1/spin/{id}?since=n
        API-->>App: yeni kareler (JPEG, kind: key/tween)
        App->>U: Görüntüleyici dolar, ilerleme ve kalan süre
    end
    U->>App: Parmakla çevir (eylemsizlikle durur)
    alt Ekrandan çıkış
        App->>API: DELETE /api/v1/spin/{id}
    else Sekme kapandı / ağ koptu
        J->>J: 30 sn sorgu yok → iptal
    end
```

## 4. Giriş ve gardırop

```mermaid
sequenceDiagram
    actor U as Kullanıcı
    participant App as Flutter
    participant A as Supabase Auth
    participant S as Storage (wardrobe_images)
    participant D as wardrobe tablosu

    U->>App: E-posta + şifre
    App->>A: signUp / signInWithPassword (20 sn zaman aşımı)
    A-->>App: Oturum (AuthGate dinler → ana ekran)
    U->>App: Sonuç ekranında "Gardıroba Ekle"
    App->>S: uploadBinary("<kullanıcı id>/<zaman>.png")
    App->>D: insert {user_id, image_url, category}
    U->>App: Gardırop
    App->>D: select (yalnızca kendi satırları — RLS)
    U->>App: Detayda "Sil"
    App->>D: delete … returning id (0 satır → hata gösterilir)
    App->>S: remove(dosya)
```

**Veri modeli ve güvenlik**

```mermaid
erDiagram
    AUTH_USERS ||--o{ WARDROBE : "sahibi"
    WARDROBE {
        id bigint PK
        user_id uuid "auth.uid()"
        image_url text "wardrobe_images/<user_id>/…"
        category text "upper | lower | overall"
        created_at timestamptz "now()"
    }
```

- Satır düzeyi güvenlik (RLS): `select`, `insert`, `delete` yalnızca `user_id = auth.uid()` için.
- Depolama: kullanıcı yalnızca kendi klasörüne (`<user_id>/…`) yükleyebilir, okuyabilir ve silebilir. Kurulum: `supabase/setup_wardrobe.sql`.

## 5. Kullanım senaryoları

```mermaid
flowchart LR
    U(("Kullanıcı"))
    U --> UC1["Kayıt ol / giriş yap / çıkış"]
    U --> UC2["Kişi seç:<br/>galeri · uygulama içi kamera · hazır manken"]
    U --> UC3["Kıyafet seç:<br/>galeri · kamera · örnek katalog"]
    U --> UC4["Kategori seç: üst · alt · tam kıyafet"]
    U --> UC5["Sanal deneme ve önce/sonra karşılaştırma"]
    U --> UC6["360° dönüş: video veya hazır set"]
    U --> UC7["Gardırop: kaydet · süz · paylaş · sil"]
    U --> UC8["Ayarlar: dil TR/EN · tema sistem/açık/koyu"]
```

## 6. Önemli tasarım kararları

| Karar | Gerekçe |
|---|---|
| IDM-VTON (Hugging Face Space) yerine yerel CatVTON | Uzak sıra ve zaman aşımları demo için güvenilir değildi; CatVTON 8 GB VRAM'e sığıyor ve alt giyimi de destekliyor |
| 15 adım · 576×768 · rehberlik 2,5 | Ölçüm: 73,6 sn → 16,8 sn; rehberliği kapatmak süreyi yarılar ama kumaş desenini siliyor (`tests/bench_speed.py`) |
| 360° için gerçek 3D yerine "dönüş videosu + kareler" | Görüntüden 3D modeller 8 GB'a sığmıyor ve yüz/desen kalitesi düşük; kare yaklaşımı gerçek fotoğraf kalitesini korur |
| 12 ana kare + RIFE ara kare | Akıcılık için kareler arası açı küçük olmalı; 48 kareyi tek tek giydirmek 4 kat uzun sürerdi |
| Uzun işler için iş numarası + sorgulama | Tarayıcıda (Safari) uzun açık bağlantı güvenilir değil; kalp atışı sahipsiz işleri temizler |
| Gardırop için Supabase + RLS | Hazır kimlik doğrulama ve dosya depolama; her kullanıcı yalnızca kendi verisini görür |

Bilinen sınırlar: [`docs/KNOWN_LIMITATIONS.md`](docs/KNOWN_LIMITATIONS.md).
