"""CatVTON motorunu sunucu olmadan doğrudan test eder.

Kullanım (proje kökünden):
  backend\\venv\\Scripts\\python tests\\smoke_tryon.py <kişi.jpg> <kıyafet.jpg> <upper|lower|overall> [çıktı.png]
Çıktı görselinin yanına maskeyi de kaydeder; süre ve VRAM kullanımını yazdırır.
"""
import os
import sys

sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "backend"))

import torch  # noqa: E402
from PIL import Image  # noqa: E402

from engine import CatVTONEngine  # noqa: E402


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        sys.exit(1)
    person_path, garment_path, category = sys.argv[1:4]
    out_path = sys.argv[4] if len(sys.argv) > 4 else f"tests/output_{category}.png"
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)

    engine = CatVTONEngine()
    print(f"Model yüklendi: {engine.gpu_info()}")
    torch.cuda.reset_peak_memory_stats()

    out = engine.run(Image.open(person_path), Image.open(garment_path), category)
    out.image.save(out_path)
    out.mask.save(out_path.replace(".png", "_mask.png"))

    peak = torch.cuda.max_memory_allocated() // (1024 * 1024)
    print(f"Kategori: {out.category} | Süre: {out.render_time_sec} sn | En yüksek VRAM: {peak} MB")
    print(f"Kaydedildi: {out_path}")


if __name__ == "__main__":
    main()
