# SeeItOn – Yol Haritası (Kasım – Aralık 2026)

Teslim: çalışan uygulama + rapor + sunum.

## 1. Hafta (3–9 Kasım) – Yerel AI motoru
- [x] Mevcut durumu git'e kaydet (`feat/catvton-backend` dalı)
- [x] IDM-VTON (Hugging Face Space) yerine CatVTON'u yerel GPU'da (RTX 5060, 8 GB) çalıştır
- [x] Backend'i yeniden yaz: kategori desteği (upper / lower / overall), gerçek süre ölçümü, anlaşılır hata mesajları
- [x] Örnek görsellerle GPU testi: upper ve overall başarılı, ~40 sn / görsel, en yüksek VRAM 4,4 GB
- [x] Kıyafet kenarındaki "hayalet" izi düzelt (repaint maskesi)
- [ ] Gerçek manken fotoğraflarıyla uygunluk değerlendirmesi ve test

## 2. Hafta (10–16 Kasım) – Alt giyim ve hatalar
- [x] Uygulamaya kategori seçimi (Üst / Alt / Tam kıyafet)
- [x] 8 test mankeni üretildi (Türk görünümü, kadın 160 cm / erkek 185 cm, S-M-L-XL) ve uygulama asset'lerine eklendi
- [x] Geliştirme için "girişi atla" butonu (sadece debug derlemede)
- [x] Örnek alt giyim katalogu (pantolon, etek, şort): RealVisXL ile 5 ürün fotoğrafı üretildi, uygulamada "Örnek" seçici
- [x] Alt giyim testi: chino / kumaş pantolon / kot başarılı (~40 sn). **Bilinen sınır:** hedef kıyafet mevcut kıyafetten kısaysa (şort, midi etek) sonuç uzuyor, çünkü CatVTON maskeyi mevcut kıyafetten çıkarıyor → raporda belgelenecek, uygulamada ipucu gösteriliyor
- [ ] (İsteğe bağlı) Kısa alt giyim için maskeyi kıyafet uzunluğuna göre kısaltma
- [ ] Alt giyimde renk doygunluğu biraz düşüyor (kot) → incele
- [ ] Zaman aşımı, bağlantı ve model hataları için düzgün hata ekranları
- [x] Sahte değerleri kaldır (fit score, sahte yükleme adımları, kullanılmayan fit/pose ayarları)
- [x] Önce/sonra karşılaştırmasını düzelt: backend 3:4 kırpılmış kişi fotoğrafını da döndürsün, karşılaştırma onu kullansın

## 3. Hafta (17–23 Kasım) – Çoklu açı, gardırop, tasarım
- [x] **360° Dönüş Denemesi** (çoklu açının yerine): dönüş videosundan 8 kare çıkarılıp her biri giydirilir, arka kareler yüzden tanınıp arka kıyafet görseli kullanılır; parmakla döndürülen görüntüleyici, canlı ilerleme, iptal/kalp atışı; uygulamayla gelen hazır set
- [x] Yan ve arka açı kalitesi denendi (3/4 ön, profil, arka sunulabilir); sınırlar KNOWN_LIMITATIONS 4–6
- [x] Akıcı dönüş: 12 ana kare + RIFE ara kareleri (48 kare), sürüklemede eylemsizlik, JPEG kareler; hazır set 20 kare (ara)
- [x] Hız: varsayılan 15 adım · 576×768 (tek görsel 73,6 → 16,8 sn; şarjda ~8 sn) — `tests/bench_speed.py`
- [ ] Gerçek bir dönüş videosundan 48 karelik hazır set (`tools/make_spin_set.py --tweens 3`)
- [ ] iPhone'da gerçek dönüş videosuyla dene (dikey döndürme, HEVC)
- [x] **Türkçe / İngilizce dil desteği** (Flutter gen-l10n): tüm ekranlar iki dilli, Ayarlar ekranından TR/EN, seçim kalıcı, 23 otomatik test
- [x] Kayıt ve giriş akışı: Supabase e-posta/şifre (doğrulamasız), oturum hatırlama (AuthGate), Ayarlar'da çıkış, TR/EN hata mesajları (hatalı şifre, kayıtlı e-posta, çok fazla deneme, bağlantı yok), 20 sn zaman aşımı, şifre göster/gizle — 43 test, gerçek hesapla tarayıcıda doğrulandı
- [ ] (Takip) Çevrimdışı açılışta süresi dolmuş oturum Supabase.initialize'ı askıda bırakabiliyor (kütüphane davranışı) — incele
- [x] Gardırop yeniden tasarlandı (krem tema, kategori filtresi, 3:4 kart ızgarası, detay: yakınlaştır/paylaş/sil) ve gerçek Supabase verisine bağlandı; kayıtlar kategoriyle, kullanıcının kendi klasörüne
- [x] Supabase kurulumu (`supabase/setup_wardrobe.sql`) çalıştırıldı; kaydet → gardırop → filtre → sil gerçek hesapla doğrulandı (2026-11-04)
- [x] Android release: INTERNET izni + yerel http backend için cleartext izni, uygulama adı "SeeItOn"
- [x] Tasarım düzenlemesi (dergi tarzı): Playfair Display + Inter, renk belirteçleri, açık/koyu tema (Ayarlar'da Sistem/Açık/Koyu, kalıcı), ortak bileşenler, sayfa geçişi; tanıtım dergi kapağı, giriş, ana, yükleme, sonuç, gardırop ekranları yenilendi — 360 px taşma testleri (TR/EN, açık/koyu)
- [x] Uygulama içi kamera (1. aşama): silüet rehberi, 3-2-1 geri sayım, Kullan/Tekrar çek, ön/arka kamera, izin reddi ve kamera yok ekranları, galeriye geçiş; Android/iOS izinleri — 92 test
- [ ] Kamerayı gerçek telefonda ve tarayıcı kamerasıyla dene
- [ ] (2. aşama, isteğe bağlı) Canlı AR önizleme: ML Kit poz algılama ile kıyafet katmanı (`CameraOverlay` yuvası hazır) + HD CatVTON render
- [x] Tekrarlanan ve kullanılmayan kodu temizle (`splash_screen.dart` kopyası, 8 widget, eski görseller)

## 4. Hafta (24–30 Kasım) – Test ve dokümantasyon
- [x] Gerçek telefonda uçtan uca test (iPhone 15 Pro, Safari, kişisel erişim noktası üzerinden): giriş, manken + örnek kıyafet, kendi fotoğrafı, sonuç, gardırop, koyu tema, EN — hepsi çalıştı (~48 sn / deneme)
- [x] Bol/açık dış giyimde vücudun ince görünmesi incelendi: maskeyi siluete kırpmak denendi, iyileşme yok → bilinen sınır olarak belgelendi ([KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md))
- [ ] Yerel iOS/Android derlemesiyle (kamera dahil) test — iOS için Mac gerekir
- [ ] Performans ölçümleri (kategori ve açı başına süre, VRAM)
- [ ] Mimari ve sıra diyagramlarını güncelle (CatVTON, çoklu açı akışı)
- [ ] Rapor taslağı

## Aralık başı – Teslim hazırlığı
- [ ] Rapor ve sunumun son hali
- [ ] Demo videosu
- [ ] Tampon süre

## Bilinçli olarak kapsam dışı bırakılanlar (raporda gerekçelendirilecek)
- **Tek fotoğraftan yeni açı / 3D üretimi:** insan yüzü ve kıyafet deseninde düşük kalite, 8 GB VRAM'e sığmıyor.
- **Video tabanlı 360° deneme:** kareler arası titreme, dakikalar süren işlem; demo için güvenilir değil.
