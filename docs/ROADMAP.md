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
- [ ] **Çoklu Açı Sanal Deneme:** kullanıcı önden / yandan / arkadan fotoğraf yükler, kıyafetin ön ve arka görseli kullanılır, her açı ayrı işlenir; sonuç ekranında kaydırarak / döndürme animasyonuyla açılar arası geçiş
- [ ] Yan ve arka açı kalitesini test et, sınırları raporda belgele
- [x] **Türkçe / İngilizce dil desteği** (Flutter gen-l10n): tüm ekranlar iki dilli, Ayarlar ekranından TR/EN, seçim kalıcı, 23 otomatik test
- [x] Kayıt ve giriş akışı: Supabase e-posta/şifre (doğrulamasız), oturum hatırlama (AuthGate), Ayarlar'da çıkış, TR/EN hata mesajları (hatalı şifre, kayıtlı e-posta, çok fazla deneme, bağlantı yok), 20 sn zaman aşımı, şifre göster/gizle — 43 test, gerçek hesapla tarayıcıda doğrulandı
- [ ] (Takip) Çevrimdışı açılışta süresi dolmuş oturum Supabase.initialize'ı askıda bırakabiliyor (kütüphane davranışı) — incele
- [x] Gardırop yeniden tasarlandı (krem tema, kategori filtresi, 3:4 kart ızgarası, detay: yakınlaştır/paylaş/sil) ve gerçek Supabase verisine bağlandı; kayıtlar kategoriyle, kullanıcının kendi klasörüne
- [x] Supabase kurulumu (`supabase/setup_wardrobe.sql`) çalıştırıldı; kaydet → gardırop → filtre → sil gerçek hesapla doğrulandı (2026-11-04)
- [x] Android release: INTERNET izni + yerel http backend için cleartext izni, uygulama adı "SeeItOn"
- [ ] Tasarım düzenlemesi: tutarlı tema, koyu mod, geçiş animasyonları
- [x] Tekrarlanan ve kullanılmayan kodu temizle (`splash_screen.dart` kopyası, 8 widget, eski görseller)

## 4. Hafta (24–30 Kasım) – Test ve dokümantasyon
- [ ] Gerçek telefonda uçtan uca test
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
