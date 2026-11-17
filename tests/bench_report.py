"""Ara rapor için tutarlı hız, başarı oranı ve kapasite ölçümü (çalışan backend'e HTTP ile).

Kullanım: backend\\venv\\Scripts\\python.exe tests\\bench_report.py [base_url=http://127.0.0.1:8000] [tekrar=10]
Çıktı: tests/output/report/bench_runs.csv, bench_summary.json ve ekrana özet.

- Güncel varsayılan profil (DPM-Solver++ 8 adım, 768x1024, kırpma + renk düzeltme) ile kategori başına [tekrar] istek
- Canlı önizleme profili (preview=true: 3 adım, 384x512) için [tekrar] istek
- Tüm istekler başarı oranına sayılır (HTTP 200 ve görsel dönmesi)
- Kapasite: aynı anda 3 istek gönderilir; GPU kilidi sırayla işler, toplam süre ölçülür
İlk (ısınma) istek ölçüme katılmaz.
"""
import csv
import json
import os
import statistics
import subprocess
import sys
import threading
import time

sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from _http import get_json, post_tryon  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, ".."))
ASSETS = os.path.join(ROOT, "see_it_on", "assets", "images")
BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8000"
REPEAT = int(sys.argv[2]) if len(sys.argv) > 2 else 10
# Haftalık regresyon (tests/regression.py) çıktıyı kendi klasörüne yazar; rapor ölçümleri ezilmez
OUT = os.environ.get("SEEITON_BENCH_OUT") or os.path.join(ROOT, "tests", "output", "report")
os.makedirs(OUT, exist_ok=True)

# Her kategori için iki farklı kişi-kıyafet çifti dönüşümlü kullanılır
CASES = {
    "upper": [("mannequins/m-m.jpg", "garments/sweater-wave.jpg"), ("mannequins/w-s.jpg", "garments/blazer.jpg")],
    "lower": [("mannequins/w-m.jpg", "garments/jeans-w.jpg"), ("mannequins/m-m.jpg", "garments/chino-m.jpg")],
    "overall": [("mannequins/w-m.jpg", "garments/blazer.jpg"), ("mannequins/m-l.jpg", "garments/shirt-stripe.jpg")],
}


def read(rel):
    with open(os.path.join(ASSETS, rel), "rb") as f:
        return f.read()


def power_state():
    """Windows: BatteryStatus 2 = şarjda (AC). Pil yoksa 'masaüstü'."""
    try:
        out = subprocess.run(
            ["powershell", "-NoProfile", "-Command", "(Get-CimInstance Win32_Battery).BatteryStatus"],
            capture_output=True, text=True, timeout=20,
        ).stdout.strip()
        return {"2": "AC (şarjda)", "1": "pil"}.get(out, f"bilinmiyor ({out or 'pil yok'})")
    except Exception as e:
        return f"bilinmiyor ({e})"


def stats(xs):
    if not xs:
        return {}
    return {
        "n": len(xs), "mean": round(statistics.mean(xs), 2),
        "std": round(statistics.stdev(xs), 2) if len(xs) > 1 else 0.0,
        "min": round(min(xs), 2), "max": round(max(xs), 2), "median": round(statistics.median(xs), 2),
    }


def main():
    health = get_json(f"{BASE}/health")
    power = power_state()
    print(f"Backend: {health}\nGüç durumu: {power}\n")
    rows = []

    # Isınma (ölçüme katılmaz)
    p, g = CASES["upper"][0]
    post_tryon(BASE, read(p), read(g), "upper")

    def run(profile, category, person, garment, preview):
        code, data, wall = post_tryon(BASE, read(person), read(garment), category, preview=preview)
        ok = code == 200 and bool(data.get("image_base64"))
        rows.append({
            "profile": profile, "category": category, "person": person, "garment": garment,
            "http": code, "ok": ok, "render_time": data.get("render_time"), "wall_time": round(wall, 3),
            "width": data.get("width"), "height": data.get("height"),
            "error": "" if ok else str(data.get("detail", ""))[:200],
        })
        print(f"{profile:8} {category:7} http={code} render={data.get('render_time')} wall={wall:.2f}s")

    for category, pairs in CASES.items():
        for i in range(REPEAT):
            person, garment = pairs[i % len(pairs)]
            run("full", category, person, garment, False)
    for i in range(REPEAT):
        person, garment = CASES["upper"][i % 2]
        run("preview", "upper", person, garment, True)

    # Kapasite: 3 eşzamanlı istek
    results = []

    def worker(k):
        person, garment = CASES["upper"][k % 2]
        results.append(post_tryon(BASE, read(person), read(garment), "upper"))

    t0 = time.perf_counter()
    threads = [threading.Thread(target=worker, args=(k,)) for k in range(3)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    concurrent_total = time.perf_counter() - t0
    concurrent_ok = sum(1 for code, data, _ in results if code == 200)

    with open(os.path.join(OUT, "bench_runs.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    summary = {"backend": health, "power": power, "repeat": REPEAT, "by_profile_category": {}}
    for profile in ("full", "preview"):
        for category in ("upper", "lower", "overall"):
            sel = [r for r in rows if r["profile"] == profile and r["category"] == category]
            if not sel:
                continue
            okr = [r for r in sel if r["ok"]]
            summary["by_profile_category"][f"{profile}/{category}"] = {
                "requests": len(sel), "succeeded": len(okr),
                "render_time": stats([r["render_time"] for r in okr]),
                "wall_time": stats([r["wall_time"] for r in okr]),
            }
    total = len(rows)
    succeeded = sum(r["ok"] for r in rows)
    full_ok = [r["wall_time"] for r in rows if r["profile"] == "full" and r["ok"]]
    summary["success_rate"] = {"requests": total, "succeeded": succeeded, "rate": round(succeeded / total, 4)}
    summary["errors"] = [r["error"] for r in rows if not r["ok"]]
    summary["capacity"] = {
        "sequential_images_per_min": round(60 / statistics.mean(full_ok), 1) if full_ok else None,
        "concurrent_3_total_s": round(concurrent_total, 2),
        "concurrent_3_succeeded": concurrent_ok,
        "concurrent_3_wall_each": [round(w, 2) for _, _, w in results],
    }
    with open(os.path.join(OUT, "bench_summary.json"), "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
