"""Uygulamayla gelen hazır 360° dönüş setini üretir (backend kapalıyken, GPU gerekir).

Kullanım:
    backend\\venv\\Scripts\\python.exe tools\\make_spin_set.py <kişi klasörü> <ön görsel> [--back arka] [--mirror]
        [--out see_it_on/assets/images/spin/demo] [--title-tr "..."] [--title-en "..."]

Kişi klasöründeki görseller ada göre sıralanır (01_..., 02_...). Adı "back" içeren ya da yüzü görünmeyen
karelerde kıyafetin arka görseli kullanılır. --mirror, son kare hariç karelerin aynalanmış kopyalarını
ters sırada ekleyerek yarım turu tam tura tamamlar (ön34, yan, arka → ön34, yan, arka, yan', ön34').
--tweens 3: komşu kareler (ve son→ilk) arasına RIFE ile ara kareler ekler; dönüş akıcılaşır.
--keys-from <klasör>: giydirme yapmadan o klasördeki frame_*.jpg'leri ana kare olarak kullanır
    (örn. mevcut seti yeniden giydirmeden ara kareli hâle getirmek için; kişi/ön görsel yok sayılır).
"""
import argparse
import glob
import json
import os
import sys

sys.stdout.reconfigure(encoding="utf-8")
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(ROOT, "backend"))

from PIL import Image, ImageOps  # noqa: E402

from engine import CatVTONEngine  # noqa: E402


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("people", nargs="?")
    ap.add_argument("front", nargs="?")
    ap.add_argument("--tweens", type=int, default=0, help="ana kareler arası RIFE ara kare sayısı (1, 3, 7)")
    ap.add_argument("--keys-from")
    ap.add_argument("--back")
    ap.add_argument("--mirror", action="store_true")
    ap.add_argument("--category", default="upper")
    ap.add_argument("--out", default=os.path.join(ROOT, "see_it_on", "assets", "images", "spin", "demo"))
    ap.add_argument("--title-tr", default="Erkek manken · Blazer")
    ap.add_argument("--title-en", default="Male mannequin · Blazer")
    a = ap.parse_args()

    if a.keys_from:
        keys = sorted(glob.glob(os.path.join(a.keys_from, "frame_*.jpg")), key=lambda p: int(p.rsplit("_", 1)[1][:-4]))
        results = [Image.open(p).convert("RGB") for p in keys]
        if a.tweens:
            from interpolator import RifeInterpolator
            results = expand_with_tweens(results, a.tweens, RifeInterpolator.from_hub().between)
        write_set(results, a)
        return

    paths = sorted(p for p in glob.glob(os.path.join(a.people, "*")) if p.lower().endswith((".png", ".jpg", ".jpeg")))
    if not paths:
        sys.exit(f"Kişi görseli bulunamadı: {a.people}")
    front = Image.open(a.front).convert("RGB")
    back = Image.open(a.back).convert("RGB") if a.back else None
    engine = CatVTONEngine()

    results = []
    for p in paths:
        person = ImageOps.exif_transpose(Image.open(p)).convert("RGB")
        is_back = "back" in os.path.basename(p).lower() or engine.is_back_view(person)
        garment = back if (is_back and back is not None) else front
        out = engine.run(person, garment, a.category)
        results.append(out.image)
        print(f"{os.path.basename(p)}: {'arka' if is_back else 'ön'} · {out.render_time_sec} sn", flush=True)

    if a.mirror and len(results) > 1:
        results += [im.transpose(Image.FLIP_LEFT_RIGHT) for im in reversed(results[:-1])]
    if a.tweens and len(results) > 1:
        results = expand_with_tweens(results, a.tweens, engine.interpolate)
    write_set(results, a)


def expand_with_tweens(keys: list, n: int, between) -> list:
    """Her komşu ana kare çiftinin ve son→ilk çiftinin arasına `n` ara kare koyar (tur kapanır)."""
    size = keys[0].size
    keys = [k.resize(size, Image.LANCZOS) if k.size != size else k for k in keys]
    out = []
    for i, k in enumerate(keys):
        out.append(k)
        out += between(k, keys[(i + 1) % len(keys)], n)
    return out


def write_set(results: list, a) -> None:
    # Kareler önce belleğe alındığı için aynı klasöre yazmak güvenli
    os.makedirs(a.out, exist_ok=True)
    for old in glob.glob(os.path.join(a.out, "frame_*.jpg")):
        os.remove(old)
    for i, im in enumerate(results):
        im.convert("RGB").resize((768, 1024), Image.LANCZOS).save(os.path.join(a.out, f"frame_{i}.jpg"), quality=90)
    with open(os.path.join(a.out, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump({"title_tr": a.title_tr, "title_en": a.title_en, "frames": len(results)}, f, ensure_ascii=False, indent=2)
    print(f"{len(results)} kare yazıldı → {a.out}")


if __name__ == "__main__":
    main()
