"""Hız/kalite ölçümü: adım sayısı, çözünürlük ve rehberlik (guidance) kombinasyonları (backend kapalıyken).

Kullanım: backend\\venv\\Scripts\\python.exe tests\\bench_speed.py [kişi.jpg] [kıyafet.jpg]
Çıktı: tests/output/bench/bench.csv ve bench_sheet.jpg (her ayar bir sütun, başlıkta süre)
"""
import csv
import os
import sys
import time

sys.stdout.reconfigure(encoding="utf-8")
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(ROOT, "backend"))

import torch  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

from engine import CatVTONEngine  # noqa: E402

ASSETS = os.path.join(ROOT, "see_it_on", "assets", "images")
PERSON = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ASSETS, "mannequins", "m-m.jpg")
GARMENT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ASSETS, "garments", "blazer.jpg")
OUT = os.path.join(ROOT, "tests", "output", "bench")

# (adım, genişlik, yükseklik, rehberlik)
CONFIGS = [
    (30, 768, 1024, 2.5),  # şu anki ayar
    (20, 768, 1024, 2.5),
    (20, 768, 1024, 1.0),
    (20, 576, 768, 2.5),
    (15, 576, 768, 2.5),
    (15, 576, 768, 1.0),
]


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    person, garment = Image.open(PERSON), Image.open(GARMENT)
    engine = CatVTONEngine()
    engine.width, engine.height = 576, 768
    engine.run(person, garment, "upper", steps=4)  # ısınma (ilk çağrı derleme/bellek ayırma)
    rows, tiles = [], []
    for steps, w, h, g in CONFIGS:
        engine.width, engine.height = w, h
        torch.cuda.reset_peak_memory_stats()
        start = time.perf_counter()
        out = engine.run(person, garment, "upper", steps=steps, guidance_scale=g)
        total = time.perf_counter() - start
        peak = torch.cuda.max_memory_allocated() / 2**20
        rows.append({"steps": steps, "size": f"{w}x{h}", "guidance": g, "model_s": out.render_time_sec,
                     "total_s": round(total, 2), "peak_vram_mb": round(peak)})
        print(rows[-1], flush=True)
        tile = out.image.resize((384, 512))
        d = ImageDraw.Draw(tile)
        d.rectangle((0, 0, 384, 44), fill=(0, 0, 0))
        d.text((8, 4), f"{steps} adım · {w}x{h} · g={g}", fill="white")
        d.text((8, 22), f"{out.render_time_sec:.1f} sn · {peak:.0f} MB", fill="white")
        tiles.append(tile)
    with open(os.path.join(OUT, "bench.csv"), "w", newline="", encoding="utf-8") as f:
        wr = csv.DictWriter(f, fieldnames=list(rows[0]))
        wr.writeheader()
        wr.writerows(rows)
    sheet = Image.new("RGB", (384 * len(tiles), 512), "white")
    for i, t in enumerate(tiles):
        sheet.paste(t, (384 * i, 0))
    sheet.save(os.path.join(OUT, "bench_sheet.jpg"), quality=90)
    print("tamam", flush=True)


if __name__ == "__main__":
    main()
