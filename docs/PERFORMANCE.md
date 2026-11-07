# SeeItOn – Performans Ölçümleri

Bütün ölçümler aynı bilgisayarda, yerel GPU ile yapıldı: **NVIDIA GeForce RTX 5060 Laptop (8 GB)**, PyTorch bf16, CatVTON + DensePose + SCHP. Süreler yalnızca modelin çalışmasını kapsar (maske + difüzyon + birleştirme); ağ aktarımı hariçtir.

## 1. Kategori başına süre (varsayılan profil)

Varsayılan profil: **15 adım · 576×768 · rehberlik 2,5**. Ölçüm: 2026-11-07, bilgisayar şarjda, Windows güç planı "Performance", her test 3 tekrar (ısınmadan sonra). Betik: `tests/bench_categories.py`.

| Test | Tekrar | Ortalama (sn) | En az | En çok | En yüksek VRAM (MB) |
|---|---|---|---|---|---|
| Tek görsel · üst giyim | 3 | 8,2 | 8,2 | 8,3 | 3 743 |
| Tek görsel · alt giyim | 3 | 8,3 | 8,2 | 8,3 | 3 743 |
| Tek görsel · tam kıyafet | 3 | 8,4 | 8,3 | 8,5 | 3 743 |
| 360° dönüş · 12 ana + 36 ara kare | 1 | 110,8 | — | — | 3 743 |

- Kategori süreyi neredeyse etkilemiyor; işi belirleyen çözünürlük ve adım sayısı.
- Dönüşte 36 ara karenin (RIFE) toplam süresi **1,5 sn**; geri kalan ~109 sn, 12 ana karenin giydirilmesi ve arka kare tanımadır (kare başına ~9 sn).
- Uygulama ilk kareyi ~10 sn içinde gösterir; kareler geldikçe görüntüleyici dolar.

## 2. Hız/kalite ayarları

Aynı manken ve ceketle, tek görsel. Betik: `tests/bench_speed.py`. Bu ölçüm bilgisayar **pildeyken** (2026-11-05) yapıldı; şarjdaki süreler yaklaşık yarısıdır (bkz. 1. tablo: 16,8 → 8,2 sn).

| Adım | Çözünürlük | Rehberlik | Süre (sn) | En yüksek VRAM (MB) | Kalite |
|---|---|---|---|---|---|
| 30 | 768×1024 | 2,5 | 73,6 | 4 423 | Başlangıç ayarı |
| 20 | 768×1024 | 2,5 | 51,9 | 4 423 | Neredeyse aynı |
| 20 | 768×1024 | 1,0 | 26,7 | 4 422 | Kumaş deseni soluklaşıyor |
| 20 | 576×768 | 2,5 | 22,7 | 3 737 | Desen ve yaka korunuyor |
| **15** | **576×768** | **2,5** | **16,8** | **3 737** | **Seçilen profil** |
| 15 | 576×768 | 1,0 | 9,3 | 3 737 | Desen kayboluyor |

**Sonuç:** Rehberliği kapatmak süreyi yarıya indiriyor ama kıyafet desenini siliyor; çözünürlük ve adım sayısını düşürmek kaliteyi koruyarak **4,4 kat** hızlandırdı. Seçilen profil şarjda tek görseli ~8 sn'de üretiyor.

## 3. Güç durumunun etkisi

Aynı profil (15 adım · 576×768): pilde 16,8 sn, şarjda + "Performance" planında 8,2 sn. Sunum ve demolarda bilgisayar şarja takılı ve güç planı "En iyi performans" olmalıdır.

## 4. Ölçümleri tekrarlamak

Backend kapalıyken (GPU boş olmalı):

```
backend\venv\Scripts\python.exe tests\bench_categories.py 3
backend\venv\Scripts\python.exe tests\bench_speed.py
```

Çıktılar `tests/output/bench/` altına CSV ve karşılaştırma görseli olarak yazılır.
