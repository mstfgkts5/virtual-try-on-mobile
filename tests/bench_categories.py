"""Rapor için performans ölçümü: kategori başına süre/VRAM ve 12 karelik dönüş (backend kapalıyken).

Kullanım: backend\\venv\\Scripts\\python.exe tests\\bench_categories.py [tekrar=3]
Çıktı: tests/output/bench/categories.csv ve ekrana Markdown tablo.
Not: süreler güç durumuna bağlıdır (şarjda / pilde); ölçüm sırasında durumu not edin.
"""
import csv
import os
import statistics
import sys
import time

sys.stdout.reconfigure(encoding="utf-8")
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(ROOT, "backend"))

import torch  # noqa: E402
from PIL import Image  # noqa: E402

from engine import CatVTONEngine  # noqa: E402

ASSETS = os.path.join(ROOT, "see_it_on", "assets", "images")
REPEAT = int(sys.argv[1]) if len(sys.argv) > 1 else 3
OUT = os.path.join(ROOT, "tests", "output", "bench")
CASES = [
    ("upper", "mannequins/m-m.jpg", "garments/blazer.jpg"),
    ("lower", "mannequins/m-m.jpg", "garments/chino-m.jpg"),
    ("overall", "mannequins/w-m.jpg", "garments/blazer.jpg"),  # süre ölçümü için; görsel kalite değerlendirilmez
]


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    engine = CatVTONEngine(576, 768)
    warm = Image.open(os.path.join(ASSETS, CASES[0][1]))
    engine.run(warm, Image.open(os.path.join(ASSETS, CASES[0][2])), "upper", steps=4)
    rows = []
    for category, person, garment in CASES:
        p, g = Image.open(os.path.join(ASSETS, person)), Image.open(os.path.join(ASSETS, garment))
        times = []
        torch.cuda.reset_peak_memory_stats()
        for _ in range(REPEAT):
            times.append(engine.run(p, g, category).render_time_sec)
        rows.append({"test": f"tek görsel · {category}", "runs": REPEAT, "mean_s": round(statistics.mean(times), 1),
                     "min_s": round(min(times), 1), "max_s": round(max(times), 1),
                     "peak_vram_mb": round(torch.cuda.max_memory_allocated() / 2**20)})
        print(rows[-1], flush=True)

    # 12 ana kare + 3'er ara kare (48 kare): giydirme + arka kare tanıma + RIFE
    person = Image.open(os.path.join(ASSETS, "mannequins", "m-m.jpg"))
    garment = Image.open(os.path.join(ASSETS, "garments", "blazer.jpg"))
    torch.cuda.reset_peak_memory_stats()
    start = time.perf_counter()
    keys = []
    for _ in range(12):
        engine.is_back_view(person)
        keys.append(engine.run(person, garment, "upper").image)
    tween_start = time.perf_counter()
    for i in range(12):
        engine.interpolate(keys[i], keys[(i + 1) % 12], 3)
    total = time.perf_counter() - start
    rows.append({"test": "360° dönüş · 12 ana + 36 ara kare", "runs": 1, "mean_s": round(total, 1),
                 "min_s": round(time.perf_counter() - tween_start, 2), "max_s": "",
                 "peak_vram_mb": round(torch.cuda.max_memory_allocated() / 2**20)})
    print(rows[-1], flush=True)

    with open(os.path.join(OUT, "categories.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print("\n| Test | Tekrar | Ortalama (sn) | En az | En çok | En yüksek VRAM (MB) |\n|---|---|---|---|---|---|")
    for r in rows:
        print(f"| {r['test']} | {r['runs']} | {r['mean_s']} | {r['min_s']} | {r['max_s']} | {r['peak_vram_mb']} |")


if __name__ == "__main__":
    main()
