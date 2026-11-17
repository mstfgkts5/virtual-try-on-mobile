# Haftalık regresyon – 2026-11-17 1641

- Commit: `a42f7d9` (+4 kaydedilmemiş değişiklik)
- Güç: AC (şarjda)
- Taban: 2026-11-14 (`8b62697`), Tam profil 768x1024, 8 adım, şarjda; tests/output/report ve tests/output/vitonhd (Ara Rapor Bölüm 10.9)
- **Sonuç: KALDI**

## Testler

| Adım | Durum | Ayrıntı |
|---|---|---|
| backend testleri | ✓ | 87 geçti, 0 kaldı |
| statik analiz | ✓ | sorun yok |
| Flutter testleri | ✓ | 193 geçti, 0 kaldı |
| hız ölçümü çalıştı | ✓ |  |
| kalite ölçümü çalıştı | ✓ |  |

## Ölçümler (taban ile)

| Ölçüm | Taban | Şimdi | Durum | Not |
|---|---|---|---|---|
| süre full/upper (s) | 14.19 | 16.04 | ✓ | sınır 16.32 |
| süre full/lower (s) | 14.59 | 17.02 | ✗ | sınır 16.78 |
| süre full/overall (s) | 14.38 | 16.33 | ✓ | sınır 16.54 |
| süre preview/upper (s) | 1.17 | 1.84 | ✗ | sınır 1.35 |
| başarı oranı | 1.0 | 1.0 | ✓ | tüm istekler |
| başarılı çift | 49 | 50 | ✓ | en az 49 |
| SSIM (yüksek iyi) | 0.8603 | 0.8652 | ✓ | en az 0.8503 |
| LPIPS (düşük iyi) | 0.1414 | 0.1357 | ✓ | en fazla 0.1514 |

Ham çıktılar bu klasördedir: pytest.txt, flutter_*.txt, bench.txt, bench_summary.json, quality_*.
