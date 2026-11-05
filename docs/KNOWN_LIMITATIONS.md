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
