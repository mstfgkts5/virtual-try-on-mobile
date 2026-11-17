"""VITON-HD test setinden eşli (paired) örneklerle kalite ölçümü: SSIM ve LPIPS.

Eşli ayar: kişi, fotoğrafta zaten giydiği kıyafetle yeniden giydirilir; sonuç orijinal fotoğrafla
karşılaştırılır (gerçek referans var). Literatürdeki VITON-HD "paired" ölçümüyle aynı yöntem.

Kullanım: backend\\venv\\Scripts\\python.exe tests\\quality_vitonhd.py [base_url=http://127.0.0.1:8000] [n=50]
Veri: Hugging Face 'TryOnVirtual/VITON-HD-TEST' (CC BY 4.0) -> tests/output/vitonhd/data
Çıktı: tests/output/vitonhd/quality.csv, quality_summary.json, examples.jpg
LPIPS için: pip install lpips (yoksa yalnızca SSIM hesaplanır)
"""
import base64
import csv
import io
import json
import os
import statistics
import sys

sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from _http import get_json, post_tryon  # noqa: E402

import numpy as np  # noqa: E402
from huggingface_hub import HfApi, hf_hub_download  # noqa: E402
from PIL import Image  # noqa: E402
from skimage.metrics import structural_similarity  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, ".."))
BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8000"
N = int(sys.argv[2]) if len(sys.argv) > 2 else 50
REPO = "TryOnVirtual/VITON-HD-TEST"
# Haftalık regresyon (tests/regression.py) çıktıyı kendi klasörüne yazar; veri her zaman aynı yerden okunur
OUT = os.environ.get("SEEITON_QUALITY_OUT") or os.path.join(ROOT, "tests", "output", "vitonhd")
DATA = os.path.join(ROOT, "tests", "output", "vitonhd", "data")
os.makedirs(OUT, exist_ok=True)
os.makedirs(DATA, exist_ok=True)


def pick_pairs():
    files = HfApi().list_repo_files(REPO, repo_type="dataset")
    folders = sorted({f.split("/")[0] for f in files if "/" in f})
    print("Veri klasörleri:", folders)
    person_dir = next((d for d in ("image", "images", "person", "model") if d in folders), None)
    if person_dir is None or "cloth" not in folders:
        raise SystemExit(f"Kişi/kıyafet klasörü bulunamadı: {folders}")
    names = lambda d: {f.split("/", 1)[1] for f in files if f.startswith(d + "/") and f.lower().endswith((".jpg", ".png"))}
    common = sorted(names(person_dir) & names("cloth"))
    print(f"Eşli örnek: {len(common)} (kişi klasörü: {person_dir}); ilk {N} kullanılacak")
    return person_dir, common[:N]


def fetch(path):
    return hf_hub_download(REPO, path, repo_type="dataset", local_dir=DATA)


def load_lpips():
    try:
        import lpips
        import torch
        model = lpips.LPIPS(net="alex", verbose=False)
        def score(a, b):
            ta = torch.from_numpy(a).permute(2, 0, 1)[None].float() / 127.5 - 1
            tb = torch.from_numpy(b).permute(2, 0, 1)[None].float() / 127.5 - 1
            with torch.no_grad():
                return float(model(ta, tb))
        return score
    except Exception as e:
        print("LPIPS kullanılamıyor (pip install lpips):", e)
        return None


def main():
    print("Backend:", get_json(f"{BASE}/health"))
    person_dir, pairs = pick_pairs()
    lp = load_lpips()
    rows, examples = [], []
    for i, name in enumerate(pairs):
        pp, cp = fetch(f"{person_dir}/{name}"), fetch(f"cloth/{name}")
        with open(pp, "rb") as f:
            person = f.read()
        with open(cp, "rb") as f:
            cloth = f.read()
        code, data, wall = post_tryon(BASE, person, cloth, "upper")
        if code != 200:
            rows.append({"name": name, "http": code, "ssim": None, "lpips": None, "render_time": None})
            print(f"[{i + 1}/{len(pairs)}] {name} HATA {code}: {data.get('detail')}")
            continue
        res = Image.open(io.BytesIO(base64.b64decode(data["image_base64"]))).convert("RGB")
        gt = Image.open(io.BytesIO(base64.b64decode(data["person_base64"]))).convert("RGB").resize(res.size, Image.BICUBIC)
        a, b = np.asarray(res), np.asarray(gt)
        s = structural_similarity(a, b, channel_axis=2, data_range=255)
        l = lp(a, b) if lp else None
        rows.append({"name": name, "http": code, "ssim": round(s, 4), "lpips": None if l is None else round(l, 4),
                     "render_time": data.get("render_time")})
        print(f"[{i + 1}/{len(pairs)}] {name} SSIM={s:.4f} LPIPS={l} t={data.get('render_time')}s")
        if len(examples) < 4:
            examples.append((gt, Image.open(cp).convert("RGB"), res))

    with open(os.path.join(OUT, "quality.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    ok = [r for r in rows if r["ssim"] is not None]
    def st(key):
        xs = [r[key] for r in ok if r[key] is not None]
        return {"n": len(xs), "mean": round(statistics.mean(xs), 4), "std": round(statistics.stdev(xs), 4)} if len(xs) > 1 else None
    summary = {
        "dataset": REPO, "setting": "paired, upper body", "pairs_requested": len(pairs), "succeeded": len(ok),
        "resolution": f"{res.size[0]}x{res.size[1]}" if ok else None,
        "ssim": st("ssim"), "lpips_alex": st("lpips"), "render_time": st("render_time"),
    }
    with open(os.path.join(OUT, "quality_summary.json"), "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
    print(json.dumps(summary, ensure_ascii=False, indent=2))

    # Örnek görsel: her satır referans | kıyafet | sonuç
    if examples:
        W, H, gap = 288, 384, 8
        sheet = Image.new("RGB", (3 * W + 2 * gap, len(examples) * H + (len(examples) - 1) * gap), "white")
        for r, (gt, cl, res) in enumerate(examples):
            y = r * (H + gap)
            sheet.paste(gt.resize((W, H)), (0, y))
            c = cl.copy(); c.thumbnail((W, H)); sheet.paste(c, (W + gap + (W - c.width) // 2, y + (H - c.height) // 2))
            sheet.paste(res.resize((W, H)), (2 * (W + gap), y))
        sheet.save(os.path.join(OUT, "examples.jpg"), quality=90)


if __name__ == "__main__":
    main()
