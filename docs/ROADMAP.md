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
- [ ] Örnek alt giyim katalogu (pantolon, etek, şort)
- [ ] Zaman aşımı, bağlantı ve model hataları için düzgün hata ekranları
- [ ] Sahte değerleri kaldır (fit score, simüle ilerleme çubuğu, kullanılmayan fit/pose ayarları)
- [x] Önce/sonra karşılaştırmasını düzelt: backend 3:4 kırpılmış kişi fotoğrafını da döndürsün, karşılaştırma onu kullansın

## 3. Hafta (17–23 Kasım) – Çoklu açı, gardırop, tasarım
- [ ] **Çoklu Açı Sanal Deneme:** kullanıcı önden / yandan / arkadan fotoğraf yükler, kıyafetin ön ve arka görseli kullanılır, her açı ayrı işlenir; sonuç ekranında kaydırarak / döndürme animasyonuyla açılar arası geçiş
- [ ] Yan ve arka açı kalitesini test et, sınırları raporda belgele
- [ ] Kayıt ve giriş akışı: kullanıcı kendi hesabını açıp giriş yapabilsin (Supabase Auth), hata mesajları Türkçe, oturum açıkken uygulama doğrudan ana ekrana gitsin, çıkış yap butonu
- [ ] Gardırobu gerçek Supabase verisine bağla
- [ ] Tasarım düzenlemesi: tutarlı tema, koyu mod, geçiş animasyonları
- [ ] Tekrarlanan kodu temizle (`splash_screen.dart` = `result_screen.dart` kopyası)

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
