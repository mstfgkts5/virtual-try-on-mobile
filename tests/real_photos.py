"""Gerçek (izinli) fotoğraflarla deneme; rapora konacak görsellerde yüzler bulanıklaştırılır.

Kullanım: backend\\venv\\Scripts\\python.exe tests\\real_photos.py <fotoğraf_klasörü> [base_url=http://127.0.0.1:8000]
Klasördeki her .jpg/.png kişi fotoğrafı için bir üst ve bir alt giyim denenir.
Çıktı: tests/output/real/real_photos.jpg (yüzler bulanık), real_photos.json (süre ve durum)
Ham sonuçlar diske yazılmaz; yalnızca yüzü bulanıklaştırılmış özet görsel kaydedilir.
"""
import base64
import io
import json
import os
import sys

sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from _http import post_tryon  # noqa: E402

import cv2  # noqa: E402
import numpy as np  # noqa: E402
from PIL import Image, ImageFilter  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, ".."))
ASSETS = os.path.join(ROOT, "see_it_on", "assets", "images", "garments")
SRC = sys.argv[1]
BASE = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8000"
OUT = os.path.join(ROOT, "tests", "output", "real")
os.makedirs(OUT, exist_ok=True)
GARMENTS = [("upper", "sweater-wave.jpg"), ("lower", "jeans-w.jpg")]
CASCADE = cv2.CascadeClassifier(os.path.join(cv2.data.haarcascades, "haarcascade_frontalface_default.xml"))


def blur_faces(img: Image.Image) -> Image.Image:
    """Yüz bulunursa geniş bir bölgeyi güçlü bulanıklaştırır; bulunamazsa üst %22'yi bulanıklaştırır."""
    arr = cv2.cvtColor(np.asarray(img), cv2.COLOR_RGB2GRAY)
    faces = CASCADE.detectMultiScale(arr, scaleFactor=1.1, minNeighbors=5, minSize=(24, 24))
    out = img.copy()
    boxes = [(x, y, w, h) for x, y, w, h in faces]
    if not boxes:  # güvenli taraf: baş bölgesi
        boxes = [(0, 0, img.width, int(img.height * 0.22))]
    for x, y, w, h in boxes:
        pad = int(0.35 * max(w, h))
        box = (max(0, x - pad), max(0, y - pad), min(img.width, x + w + pad), min(img.height, y + h + pad))
        out.paste(out.crop(box).filter(ImageFilter.GaussianBlur(radius=max(12, w // 4))), box[:2])
    return out


def main():
    photos = sorted(f for f in os.listdir(SRC) if f.lower().endswith((".jpg", ".jpeg", ".png")))
    log, rows = [], []
    for name in photos:
        with open(os.path.join(SRC, name), "rb") as f:
            person = f.read()
        row = []
        for category, garment in GARMENTS:
            with open(os.path.join(ASSETS, garment), "rb") as f:
                code, data, wall = post_tryon(BASE, person, f.read(), category)
            log.append({"photo": name, "category": category, "http": code, "render_time": data.get("render_time"),
                        "wall_time": round(wall, 2)})
            print(log[-1])
            if code != 200:
                continue
            if not row:
                row.append(blur_faces(Image.open(io.BytesIO(base64.b64decode(data["person_base64"]))).convert("RGB")))
            row.append(blur_faces(Image.open(io.BytesIO(base64.b64decode(data["image_base64"]))).convert("RGB")))
        if row:
            rows.append(row)
    with open(os.path.join(OUT, "real_photos.json"), "w", encoding="utf-8") as f:
        json.dump(log, f, ensure_ascii=False, indent=2)
    if rows:
        W, H, gap = 288, 384, 8
        cols = max(len(r) for r in rows)
        sheet = Image.new("RGB", (cols * W + (cols - 1) * gap, len(rows) * H + (len(rows) - 1) * gap), "white")
        for r, row in enumerate(rows):
            for c, im in enumerate(row):
                sheet.paste(im.resize((W, H)), (c * (W + gap), r * (H + gap)))
        sheet.save(os.path.join(OUT, "real_photos.jpg"), quality=90)
        print("Kaydedildi:", os.path.join(OUT, "real_photos.jpg"))


if __name__ == "__main__":
    main()
