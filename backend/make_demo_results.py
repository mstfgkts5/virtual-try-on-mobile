"""Çevrimdışı demo için hazır sonuçları üretir.

Uygulamadaki her hazır manken × aynı bölgedeki her örnek kıyafet için bir deneme yapılır
ve sonuçlar see_it_on/assets/images/demo/ altına yazılır. Sunucuya ulaşılamazsa uygulama
bu sonuçları gösterebilir (lib/services/demo_results.dart).

Ayarlar uygulamanınkiyle aynıdır: 768x1024, 8 adım, guidance 2.5, seed 42, kişi kırpma ve
renk düzeltme açık (main.py process_tryon). Kullanım: venv\\Scripts\\python.exe make_demo_results.py
"""
import json
import os
import sys
import time

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ASSETS = os.path.join(ROOT, "see_it_on", "assets", "images")
OUT = os.path.join(ASSETS, "demo")

# home_screen.dart ile aynı listeler; kadın alt giyimleri kadın, erkek alt giyimleri erkek mankenlerde
MANNEQUINS = ["w-s", "w-m", "w-l", "w-xl", "m-s", "m-m", "m-l", "m-xl"]
UPPER = ["blazer", "shirt-stripe", "hoodie", "sweater-wave", "turtleneck"]
LOWER = {"w": ["jeans-w", "skirt-w", "shorts-w"], "m": ["chino-m", "trousers-m"]}

# 17 Kasım üretiminde gözle elenen çiftler: demo yanlış sonuç göstermesin diye listede yok.
# Bu çiftlerde uygulama demo düğmesini hiç göstermez (sunucu açıkken deneme yine yapılabilir).
REJECTED = {
    # CatVTON taytın üstüne kısa alt giyimi oturtamıyor (docs/KNOWN_LIMITATIONS.md):
    # etek bol pantolona, şort uzun pantolona dönüşüyor
    **{(m, "skirt-w"): "etek pantolona dönüşüyor" for m in ("w-s", "w-m", "w-l", "w-xl")},
    **{(m, "shorts-w"): "şort uzun pantolona dönüşüyor" for m in ("w-s", "w-m", "w-l", "w-xl")},
    ("m-xl", "hoodie"): "gövdede dantel benzeri yapay desen",
    ("m-xl", "sweater-wave"): "desen bulanık",
    ("m-l", "hoodie"): "alt kenarda koyu leke",
}

STEPS, GUIDANCE, SEED = 8, 2.5, 42
QUALITY = 85  # 768x1024 JPEG ~100 KB; uygulama paketi küçük kalsın


def all_pairs():
    for m in MANNEQUINS:
        for g in UPPER:
            yield m, g, "upper"
        for g in LOWER[m[0]]:
            yield m, g, "lower"


def pairs():
    """Demoya giren çiftler: elenenler hariç."""
    return [p for p in all_pairs() if (p[0], p[1]) not in REJECTED]


def main(only=None):
    from engine import CatVTONEngine  # torch yalnızca üretimde yüklenir; testler listeyi hafifçe okur

    os.makedirs(OUT, exist_ok=True)
    engine = CatVTONEngine(768, 1024)
    items, log = [], []
    todo = [p for p in pairs() if only is None or p[0] in only]
    for n, (m, g, cat) in enumerate(todo, 1):
        person = Image.open(os.path.join(ASSETS, "mannequins", m + ".jpg"))
        garment = Image.open(os.path.join(ASSETS, "garments", g + ".jpg"))
        t0 = time.perf_counter()
        out = engine.run(person, garment, cat, STEPS, GUIDANCE, SEED, None, True)
        result_name = f"{m}__{g}.jpg"
        person_name = f"{m}__person_{cat}.jpg"
        out.image.convert("RGB").save(os.path.join(OUT, result_name), quality=QUALITY)
        # Kırpılmış kişi fotoğrafı aynı manken ve bölge için hep aynı; bir kez yazılır
        person_path = os.path.join(OUT, person_name)
        if not os.path.exists(person_path):
            out.person.convert("RGB").save(person_path, quality=QUALITY)
        items.append({
            "mannequin": m,
            "garment": g,
            "category": out.category,
            "result": result_name,
            "person": person_name,
            "render_time": out.render_time_sec,
        })
        line = f"{n}/{len(todo)} {m} {g} {cat} render {out.render_time_sec}s wall {time.perf_counter() - t0:.1f}s"
        log.append(line)
        print(line, flush=True)

    with open(os.path.join(OUT, "index.json"), "w", encoding="utf-8") as f:
        json.dump({
            "note": "backend/make_demo_results.py ile üretildi; 768x1024, 8 adım, seed 42",
            "items": items,
        }, f, ensure_ascii=False, indent=1)
    print(f"{len(items)} sonuç yazıldı -> {OUT}")


if __name__ == "__main__":
    main(set(sys.argv[1:]) or None)
