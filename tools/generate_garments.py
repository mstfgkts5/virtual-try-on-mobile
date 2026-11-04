"""Sanal deneme testleri için e-ticaret tarzı kıyafet ürün fotoğrafları üretir (RealVisXL V5).

Gerçek marka ürünü kullanılmadığı için telif sorunu yoktur. Her kıyafet için birkaç aday üretilir.

Kullanım (proje kökünden):
  backend\\venv\\Scripts\\python tools\\generate_garments.py                  # hepsi, 3'er aday
  backend\\venv\\Scripts\\python tools\\generate_garments.py --only jeans-w --candidates 4
Çıktı: test_images/garments/<id>/<seed>.png ve kıyafet başına karşılaştırma görseli _sheets/<id>.png
"""
import argparse
import os
import sys

sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0, os.path.dirname(__file__))

import torch  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

from generate_mannequins import load_pipeline  # noqa: E402

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "test_images", "garments")
SIZE = 1024

# category: backend'e gidecek kategori (upper / lower / overall)
GARMENTS = [
    {"id": "jeans-w", "category": "lower", "name": "Yüksek bel mavi kot (kadın)",
     "desc": "women's high-waist straight leg blue denim jeans"},
    # Etek fotoğrafları genelde giyilmiş çekildiği için "spread out, garment only" eklenmeden kişi çiziliyor
    {"id": "skirt-w", "category": "lower", "name": "Siyah pliseli midi etek",
     "desc": "a black pleated midi skirt spread out flat, garment only"},
    {"id": "chino-m", "category": "lower", "name": "Bej chino pantolon (erkek)",
     "desc": "men's beige slim chino trousers"},
    {"id": "trousers-m", "category": "lower", "name": "Lacivert kumaş pantolon (erkek)",
     "desc": "men's navy blue tailored wool dress trousers"},
    {"id": "shorts-w", "category": "lower", "name": "Açık mavi kot şort",
     "desc": "women's light blue denim shorts"},
]

# "flat lay, top-down" başa yazılmazsa model kıyafeti bir kişinin üzerinde çiziyor;
# CatVTON o zaman bacakları/ayakkabıları da kıyafetin parçası sanıyor
PROMPT = ("flat lay top-down photo, {desc} laid flat on a plain white surface, no person, "
          "whole garment fully visible and centered, e-commerce product photo, soft even light, "
          "sharp fabric texture, photorealistic")
NEGATIVE = ("person, woman, man, model, worn, body, legs, feet, shoes, hands, mannequin, hanger, "
            "multiple items, folded, cropped, logo, text, watermark, busy background, blurry, lowres, cartoon")


def save_sheet(gid: str, paths: list[str]):
    thumb = 320
    sheet = Image.new("RGB", (thumb * len(paths), thumb + 30), "white")
    draw = ImageDraw.Draw(sheet)
    for i, path in enumerate(paths):
        sheet.paste(Image.open(path).convert("RGB").resize((thumb, thumb)), (i * thumb, 0))
        draw.text((i * thumb + 8, thumb + 8), f"#{i + 1}  {os.path.basename(path)}", fill="black")
    os.makedirs(os.path.join(OUT_DIR, "_sheets"), exist_ok=True)
    sheet.save(os.path.join(OUT_DIR, "_sheets", f"{gid}.png"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", nargs="*")
    parser.add_argument("--candidates", type=int, default=3)
    parser.add_argument("--steps", type=int, default=30)
    parser.add_argument("--seed-start", type=int, default=2000)
    args = parser.parse_args()

    selected = [g for g in GARMENTS if not args.only or g["id"] in args.only]
    pipe = load_pipeline()
    for g in selected:
        folder = os.path.join(OUT_DIR, g["id"])
        os.makedirs(folder, exist_ok=True)
        paths = []
        for seed in range(args.seed_start, args.seed_start + args.candidates):
            image = pipe(
                prompt=PROMPT.format(desc=g["desc"]),
                negative_prompt=NEGATIVE,
                width=SIZE,
                height=SIZE,
                num_inference_steps=args.steps,
                guidance_scale=5.0,
                generator=torch.Generator("cpu").manual_seed(seed),
            ).images[0]
            out = os.path.join(folder, f"{seed}.png")
            image.save(out)
            paths.append(out)
            print(f"[{g['id']}] {g['name']} -> {out}")
        save_sheet(g["id"], paths)


if __name__ == "__main__":
    main()
