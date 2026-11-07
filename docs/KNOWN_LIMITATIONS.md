# SeeItOn – Bilinen Sınırlar

Rapordaki "Sınırlılıklar" bölümü için. Her madde gözlem, sebep ve uygulamadaki karşılığı içerir.

## 1. Kısa alt giyim uzun görünüyor
- **Gözlem:** Hedef kıyafet mevcut kıyafetten kısaysa (şort, midi etek) sonuç mevcut kıyafet boyunda çıkıyor.
- **Sebep:** CatVTON maskesini kişinin üzerindeki kıyafetten çıkarıyor; maske kısalmadığı için model alanı yeni kıyafetle dolduruyor.
- **Uygulamada:** Alt giyim seçiliyken ipucu gösteriliyor.
- **Olası iyileştirme:** Maskeyi hedef kıyafetin uzunluğuna göre kısaltmak (yapılmadı).

## 2. Bol / açık dış giyim ve bükülü kollar vücudu ince gösterebiliyor
- **Gözlem (gerçek telefon testi, 2026-11-05):** Açık, bol ve koyu bir ceket giyen ve kolu gövdeden uzakta duran bir fotoğrafta sonuç, kişiyi olduğundan zayıf gösterdi; eski ceketin kapladığı alanın bir kısmına arka plan (göl, yaprak) çizildi.
- **Sebep:** CatVTON maskesi kıyafet bölgesini dışbükey zarfla (convex hull) genişletir (`ai/CatVTON/model/cloth_masker.py`). Model bu alanda vücudun gerçek genişliğini bilemez; ürün fotoğrafındaki kıyafetin kalıbını izler ve kalan yeri arka planla doldurur.
- **Denenen çözüm:** Maskeyi kişinin siluetine (+24 px) kırpmak (`tests/shape_experiment.py`). XL mankenlerde ve düz duran, tek kat kıyafetli gerçek bir fotoğrafta varsayılan maske zaten genişliği korudu; kırpılmış maske bir iyileşme getirmedi, ceketin önünde bozulmaya yol açtı. Bu yüzden uygulanmadı.
- **Uygulamada:** 1. adım ipucu düz durulan, tam boy bir fotoğraf ister. Bu tür fotoğraflarda sorun gözlenmedi.
- **Olası iyileştirme:** Vücut şekli koşullu bir model (ör. DensePose/SMPL tabanlı) veya poz/şekil bilgisini kullanan maske; 8 GB VRAM sınırında değerlendirilmeli.

## 3. Uygulama içi kamera için HTTPS gerekir (web)
- **Gözlem:** iPhone Safari'de uygulama yerel Wi-Fi üzerinden (http) açıldığında tarayıcı kamerayı açmıyor; ekran "Galeriden seç"e yönlendiriyor.
- **Sebep:** Tarayıcılar kamerayı yalnızca güvenli bağlamda (HTTPS veya localhost) verir.
- **Uygulamada:** Galeri ve manken yolları çalışır; yerel (Android/iOS) derlemede kamera eklentisi doğrudan çalışır.
- **Demo için:** `start_demo.ps1` backend'i (8000) ve web uygulamasını (8443) kendi imzalı sertifikayla HTTPS üzerinden açar (`backend/certs/`, git dışında). Telefonda önce `https://<IP>:8000/health`, sonra `https://<IP>:8443` açılıp "bağlantı gizli değil" uyarısı bir kez kabul edilir. Gerçek bir dağıtımda tanınmış bir sertifika (ör. Let's Encrypt) gerekir.

## 4. 360° dönüş: kareler ayrı üretilir
- **Gözlem:** Dönüşteki her kare CatVTON ile ayrı giydirildiği için kumaşın kırışıkları ve deseni kareden kareye biraz değişebilir; ince desenler (kareli, ekose) düz renge yaklaşabilir.
- **Sebep:** Model kareler arası tutarlılık bilmez; gerçek 3D/video modeli 8 GB VRAM'e sığmıyor.
- **Uygulamada:** 12 giydirilmiş ana kare arasına RIFE ile 3'er ara kare eklenir (48 kare); görüntüleyici parmakla ve eylemsizlikle döner. Ölçüm (2026-11-07, 576×768, 15 adım): ana kare ~8–17 sn (bilgisayar şarjda/pilde), 3 ara kare 0,09 sn → 12 karelik dönüş ~1,5–3,5 dk.
- **Ara kare sınırı:** Komşu ana kareler arası açı büyükse (≥60°) ara karelerde hayalet/çift görüntü olur. Hazır sette tam önden görünüm olmadığı ve yarım tur aynalandığı için turun kapandığı noktada yüzde çift görüntü var; gerçek bir dönüş videosundan üretilen sette bu olmaz.

## 5. 360° dönüş: sekme kapanınca GPU'nun boşalma süresi
- **Gözlem:** Kullanıcı Safari sekmesini kapatır veya Wi-Fi koparsa iş, son durum sorgusundan 30 sn sonra iptal edilir; ancak o anda işlenen kare yarıda kesilemediği için GPU en kötü durumda ~80 sn sonra boşalır.
- **Uygulamada:** Ekrandan normal çıkışta iş hemen iptal edilir (sıradaki kareler yapılmaz).
- **Olası iyileştirme:** CatVTON'un adım döngüsüne iptal denetimi eklemek.

## 6. 360° dönüş: iPhone video biçimi
- **Gözlem:** iPhone varsayılan olarak HEVC `.MOV` kaydeder. Backend PyAV (kendi ffmpeg'i) ile bunu okur ve dikey döndürmeyi uygular; video yine açılamazsa kullanıcıya "Ayarlar → Kamera → Formatlar → En Uyumlu" ipucu gösterilir.

## 7. Canlı deneme gerçek zamanlı değil
- **Gözlem:** "Canlı dene" ekranında kamera açık kalır, ama giydirilmiş görüntü ~2–3 sn'de bir yenilenir; hareket sırasında görüntü bir önceki duruşu gösterir.
- **Sebep:** Difüzyon modeli kare başına birkaç saniye ister; gerçek zamanlı (≥15 kare/sn) deneme, sunucu sınıfı GPU'larda çalışan özel video modelleri gerektirir.
- **Uygulamada:** Önizleme 384×512 ve 10 adımla üretilir (~2,2 sn, şarjda); düşük adımda iç giysi ve kenarlarda bozulma görülebilir. "Bu kareyi kaydet" son kareyi tam kaliteyle (576×768, 15 adım) yeniden üretir.
