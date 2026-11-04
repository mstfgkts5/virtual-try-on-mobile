"""Manken adaylarını her manken için tek bir numaralı karşılaştırma görselinde birleştirir.

Kullanım (proje kökünden):  backend\\venv\\Scripts\\python tools\\contact_sheet.py [--view front]
Çıktı: test_images/mannequins/_sheets/<id>_<görünüm>.png
"""
import argparse
import glob
import json
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..", "test_images", "mannequins")
THUMB_W, THUMB_H = 300, 386  # 896x1152 oranı
LABEL_H = 34


def load_font(size: int):
    for name in ("arialbd.ttf", "arial.ttf", "DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--view", default="front")
    args = parser.parse_args()

    with open(os.path.join(ROOT, "mannequins.json"), encoding="utf-8") as f:
        specs = {m["id"]: m for m in json.load(f)}
    out_dir = os.path.join(ROOT, "_sheets")
    os.makedirs(out_dir, exist_ok=True)
    font, title_font = load_font(22), load_font(26)

    for mid, spec in specs.items():
        files = sorted(glob.glob(os.path.join(ROOT, mid, f"{args.view}_*.png")))
        if not files:
            continue
        title = (f"{mid}  |  {'Kadın' if spec['gender'] == 'female' else 'Erkek'} {spec['size']}  |  "
                 f"{spec['height_cm']} cm / {spec['weight_kg']} kg")
        sheet = Image.new("RGB", (THUMB_W * len(files), THUMB_H + LABEL_H + 44), "white")
        draw = ImageDraw.Draw(sheet)
        draw.text((12, 8), title, fill="black", font=title_font)
        for i, path in enumerate(files):
            thumb = Image.open(path).convert("RGB").resize((THUMB_W, THUMB_H), Image.Resampling.LANCZOS)
            x = i * THUMB_W
            sheet.paste(thumb, (x, 44))
            seed = os.path.splitext(os.path.basename(path))[0].split("_")[-1]
            draw.text((x + 10, 44 + THUMB_H + 5), f"#{i + 1}  (seed {seed})", fill="black", font=font)
            draw.line([(x, 44), (x, sheet.height)], fill="#cccccc", width=2)
        out = os.path.join(out_dir, f"{mid}_{args.view}.png")
        sheet.save(out)
        print(f"{mid}: {len(files)} aday -> {out}")


if __name__ == "__main__":
    main()
