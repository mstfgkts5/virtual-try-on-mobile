# Kanıt dosyaları (Ara Rapor, 9–12 Kasım 2026)

| Dosya | İçerik | Üreten |
|---|---|---|
| flutter_test.txt, flutter_analyze.txt, flutter_version.txt | 163 Flutter testi ve statik analiz çıktısı | `flutter test --coverage`, `flutter analyze` |
| pytest.txt | 51 backend testi | `pytest backend/tests` |
| bench.txt, bench_runs.csv, bench_summary.json, power.txt | Hız, başarı oranı, kapasite (40 istek; şarjda) | `tests/bench_report.py` |
| quality_log.txt, quality.csv, quality_summary.json | VITON-HD, 50 eşli örnek, SSIM / LPIPS | `tests/quality_vitonhd.py` |
| env.txt, catvton_commit.txt | Python, GPU/sürücü, sabitlenen CatVTON commit'i | – |

Betikler `tests/` altındadır; komutlar `docs/PERFORMANCE.md` ve `backend/README.md` içindedir.
