"""Vücut genişliği deneyi: varsayılan CatVTON maskesi ile kişinin siluetine kırpılmış maskeyi karşılaştırır.

Kullanım (backend kapalıyken, GPU boş olmalı):
    backend\\venv\\Scripts\\python.exe tests\\shape_experiment.py [kişi.jpg ...]
Çıktı: tests/output/shape_<kişi>.jpg (kişi | maske A | sonuç A | maske B | sonuç B)
"""
import os
import sys

sys.stdout.reconfigure(encoding="utf-8")
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(ROOT, "backend"))

import cv2  # noqa: E402
import numpy as np  # noqa: E402
import torch  # noqa: E402
from PIL import Image, ImageOps  # noqa: E402

from engine import CatVTONEngine  # noqa: E402
from utils import resize_and_crop, resize_and_padding  # noqa: E402  # type: ignore

ASSETS = os.path.join(ROOT, "see_it_on", "assets", "images")
# Kişisel fotoğraflar için çıktıyı repo dışına almak: SHAPE_OUT=<klasör>
OUT = os.environ.get("SHAPE_OUT") or os.path.join(ROOT, "tests", "output")


def silhouette_clip(mask: Image.Image, schp_lip: Image.Image, schp_atr: Image.Image, margin_px: int) -> Image.Image:
    """Maskeyi kişinin siluetine (+margin) sınırlar: model kişiyi arka planla daraltamaz."""
    person = (np.array(schp_lip) != 0) | (np.array(schp_atr) != 0)
    person = person.astype(np.uint8)
    if person.shape != np.array(mask).shape:
        person = cv2.resize(person, mask.size, interpolation=cv2.INTER_NEAREST)
    k = margin_px | 1
    person = cv2.dilate(person, np.ones((k, k), np.uint8))
    clipped = (np.array(mask.convert("L")) > 127).astype(np.uint8) & person
    return Image.fromarray(clipped * 255)


def run(engine: CatVTONEngine, person: Image.Image, garment: Image.Image, mask: Image.Image) -> Image.Image:
    blurred = engine.mask_processor.blur(mask, blur_factor=9)
    gen = torch.Generator(device=engine.device).manual_seed(42)
    out = engine.pipeline(
        image=person, condition_image=garment, mask=blurred, num_inference_steps=30,
        guidance_scale=2.5, height=engine.height, width=engine.width, generator=gen,
    )[0]
    return engine._repaint(person, blurred, out)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    people = sys.argv[1:] or [os.path.join(ASSETS, "mannequins", f"{m}.jpg") for m in ("m-xl", "w-xl")]
    garment = resize_and_padding(Image.open(os.path.join(ASSETS, "garments", "blazer.jpg")).convert("RGB"), (768, 1024))
    engine = CatVTONEngine()
    for path in people:
        person = resize_and_crop(ImageOps.exif_transpose(Image.open(path)).convert("RGB"), (768, 1024))
        parts = engine.automasker(person, "upper")
        default = parts["mask"]
        clipped = silhouette_clip(default, parts["schp_lip"], parts["schp_atr"], margin_px=24)
        res_a = run(engine, person, garment, default)
        res_b = run(engine, person, garment, clipped)
        tiles = [person, default.convert("RGB"), res_a, clipped.convert("RGB"), res_b]
        sheet = Image.new("RGB", (768 * len(tiles), 1024), "white")
        for i, t in enumerate(tiles):
            sheet.paste(t.resize((768, 1024)), (768 * i, 0))
        name = os.path.splitext(os.path.basename(path))[0]
        dest = os.path.join(OUT, f"shape_{name}.jpg")
        sheet.resize((sheet.width // 2, sheet.height // 2)).save(dest, quality=90)
        print("kaydedildi:", dest, flush=True)


if __name__ == "__main__":
    main()
