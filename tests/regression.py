"""Haftalık regresyon: tüm testleri ve ölçümleri çalıştırır, 14 Kasım ölçümleriyle karşılaştırır.

Kullanım (proje kökünde; backend 8001'de açık olmalı, run_regression.bat açar):
    backend\\venv\\Scripts\\python.exe -u tests\\regression.py [--api URL] [--repeat 3] [--pairs 50]

Adımlar: backend testleri (pytest) -> Flutter analyze + test -> hız (tests/bench_report.py)
-> VITON-HD kalite (tests/quality_vitonhd.py) -> karşılaştırma.
Çıktı: docs/evidence/regression/<tarih>/ (ham çıktılar + REGRESSION.md) ve
docs/evidence/regression/history.csv (her çalıştırma bir satır).
Herhangi bir adım başarısızsa veya ölçüm eşiği aşılırsa çıkış kodu 1'dir.
Eşikler ve karşılaştırma tabanı: tests/regression_baseline.json.
"""
import argparse
import csv
import datetime
import json
import os
import re
import subprocess
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
BASELINE = os.path.join(HERE, "regression_baseline.json")
EVIDENCE = os.path.join(ROOT, "docs", "evidence", "regression")
SPEED_KEYS = ("full/upper", "full/lower", "full/overall", "preview/upper")


# ---------------------------------------------------------------- çıktı okuma (saf, testli)

def parse_pytest(text):
    """'78 passed, 1 failed in 9.1s' -> {'passed': 78, 'failed': 1}"""
    out = {"passed": 0, "failed": 0}
    for n, word in re.findall(r"(\d+) (passed|failed|error|errors)", text):
        key = "passed" if word == "passed" else "failed"
        out[key] += int(n)
    return out


def parse_flutter_test(text):
    """Son satır '00:06 +193: All tests passed!' ya da '+192 -1: Some tests failed.'"""
    found = re.findall(r"\+(\d+)(?: ~\d+)?(?: -(\d+))?: (All tests passed|Some tests failed)", text)
    if not found:
        return {"passed": 0, "failed": 0, "ok": False}
    passed, failed, verdict = found[-1]
    return {"passed": int(passed), "failed": int(failed or 0), "ok": verdict == "All tests passed"}


def parse_flutter_analyze(text):
    if "No issues found" in text:
        return {"issues": 0, "ok": True}
    m = re.search(r"(\d+) issues? found", text)
    return {"issues": int(m.group(1)) if m else -1, "ok": False}


def compare(baseline, bench, quality, on_mains):
    """Ölçümleri tabanla karşılaştırır. Her satır: (ad, taban, şimdi, durum, not).
    durum: 'ok' | 'fail' | 'skip'. Pilde hız karşılaştırılmaz (yaklaşık iki kat yavaş, Bölüm 10.7)."""
    tol = baseline["tolerance"]
    rows = []
    if bench is None:
        rows.append(("hız ve başarı oranı", "", "", "skip", "ölçülmedi (backend kapalı)"))
    else:
        cats = bench.get("by_profile_category", {})
        for key in SPEED_KEYS:
            base = baseline["speed_render_s"][key]
            now = (cats.get(key, {}).get("render_time") or {}).get("mean")
            if now is None:
                rows.append((f"süre {key} (s)", base, None, "fail", "sonuç yok"))
            elif not on_mains:
                rows.append((f"süre {key} (s)", base, now, "skip", "pilde; şarjda ölçülmeli"))
            else:
                limit = round(base * tol["speed_ratio"], 2)
                rows.append((f"süre {key} (s)", base, now, "ok" if now <= limit else "fail", f"sınır {limit}"))
        rate = (bench.get("success_rate") or {}).get("rate")
        rows.append(("başarı oranı", baseline["success_rate"], rate,
                     "ok" if rate is not None and rate >= baseline["success_rate"] else "fail", "tüm istekler"))
    if quality is None:
        rows.append(("VITON-HD kalite", "", "", "skip", "ölçülmedi"))
    else:
        bq = baseline["quality"]
        ok_pairs = quality.get("succeeded", 0)
        need = quality.get("pairs_requested", bq["pairs"]) - tol["quality_failed_pairs"]
        rows.append(("başarılı çift", bq["succeeded"], ok_pairs, "ok" if ok_pairs >= need else "fail", f"en az {need}"))
        ssim = (quality.get("ssim") or {}).get("mean")
        lim = round(bq["ssim"] - tol["ssim_drop"], 4)
        rows.append(("SSIM (yüksek iyi)", bq["ssim"], ssim, "ok" if ssim is not None and ssim >= lim else "fail", f"en az {lim}"))
        lp = (quality.get("lpips_alex") or {}).get("mean")
        lim = round(bq["lpips"] + tol["lpips_rise"], 4)
        rows.append(("LPIPS (düşük iyi)", bq["lpips"], lp, "ok" if lp is not None and lp <= lim else "fail", f"en fazla {lim}"))
    return rows


# ---------------------------------------------------------------- çalıştırma

def run(cmd, cwd, log_path, env=None, timeout=None):
    t0 = time.perf_counter()
    proc = subprocess.run(cmd, cwd=cwd, capture_output=True, env=env, timeout=timeout)
    text = (proc.stdout + proc.stderr).decode("utf-8", errors="replace")
    with open(log_path, "w", encoding="utf-8") as f:
        f.write(text)
    return proc.returncode, text, time.perf_counter() - t0


def health(api):
    try:
        with urllib.request.urlopen(f"{api}/health", timeout=5) as r:
            return json.loads(r.read().decode("utf-8")).get("status") == "ok"
    except Exception:
        return False


def git(*args):
    try:
        return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    except Exception:
        return ""


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--api", default="http://127.0.0.1:8001")
    ap.add_argument("--flutter", default=os.environ.get("FLUTTER", r"C:\src\flutter\bin\flutter.bat"))
    ap.add_argument("--repeat", type=int, default=3, help="hız ölçümünde kategori başına istek")
    ap.add_argument("--pairs", type=int, default=50, help="VITON-HD eşli örnek sayısı")
    ap.add_argument("--skip-flutter", action="store_true")
    args = ap.parse_args()

    sys.stdout.reconfigure(encoding="utf-8")
    baseline = load_json(BASELINE)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d_%H%M")
    out = os.path.join(EVIDENCE, stamp)
    os.makedirs(out, exist_ok=True)
    commit = git("rev-parse", "--short", "HEAD")
    dirty = len([l for l in git("status", "--porcelain", "--untracked-files=no").splitlines() if l.strip()])
    print(f"Regresyon {stamp}  commit {commit}{' (+' + str(dirty) + ' değişmiş dosya)' if dirty else ''}\n", flush=True)

    steps = []  # (ad, ok, ayrıntı)

    print("[1/4] backend testleri", flush=True)
    code, text, secs = run([sys.executable, "-m", "pytest", "-q"], os.path.join(ROOT, "backend"),
                           os.path.join(out, "pytest.txt"))
    py = parse_pytest(text)
    steps.append(("backend testleri", code == 0 and py["failed"] == 0, f"{py['passed']} geçti, {py['failed']} kaldı"))

    flutter_line = "atlandı"
    if not args.skip_flutter:
        print("[2/4] flutter analyze + test", flush=True)
        app = os.path.join(ROOT, "see_it_on")
        _, text, _ = run(["cmd", "/c", args.flutter, "analyze", "--no-pub"], app, os.path.join(out, "flutter_analyze.txt"))
        an = parse_flutter_analyze(text)
        steps.append(("statik analiz", an["ok"], "sorun yok" if an["ok"] else f"{an['issues']} sorun"))
        code, text, _ = run(["cmd", "/c", args.flutter, "test", "--no-pub"], app, os.path.join(out, "flutter_test.txt"))
        ft = parse_flutter_test(text)
        steps.append(("Flutter testleri", code == 0 and ft["ok"], f"{ft['passed']} geçti, {ft['failed']} kaldı"))
        flutter_line = f"{ft['passed']}/{ft['failed']}"

    bench = quality = None
    power = "?"
    if health(args.api):
        env = dict(os.environ, SEEITON_BENCH_OUT=out, SEEITON_QUALITY_OUT=out, HF_HUB_DISABLE_XET="1")
        print(f"[3/4] hız ölçümü ({args.repeat} tekrar)", flush=True)
        code, _, _ = run([sys.executable, "-u", os.path.join(HERE, "bench_report.py"), args.api, str(args.repeat)],
                         ROOT, os.path.join(out, "bench.txt"), env=env)
        bench = load_json(os.path.join(out, "bench_summary.json")) if code == 0 else None
        steps.append(("hız ölçümü çalıştı", bench is not None, "" if bench else "bench.txt'ye bak"))
        power = (bench or {}).get("power", "?")
        print(f"[4/4] VITON-HD kalite ({args.pairs} çift)", flush=True)
        code, _, _ = run([sys.executable, "-u", os.path.join(HERE, "quality_vitonhd.py"), args.api, str(args.pairs)],
                         ROOT, os.path.join(out, "quality_log.txt"), env=env)
        quality = load_json(os.path.join(out, "quality_summary.json")) if code == 0 else None
        steps.append(("kalite ölçümü çalıştı", quality is not None, "" if quality else "quality_log.txt'ye bak"))
    else:
        steps.append(("backend erişilebilir", False, f"{args.api}/health yanıt vermedi; ölçümler atlandı"))

    on_mains = str(power).startswith("AC")
    rows = compare(baseline, bench, quality, on_mains)
    verdict = all(ok for _, ok, _ in steps) and all(r[3] != "fail" for r in rows)

    fmt = lambda v: "" if v is None else str(v)
    mark = {"ok": "✓", "fail": "✗", "skip": "–"}
    lines = [
        f"# Haftalık regresyon – {stamp.replace('_', ' ')}",
        "",
        f"- Commit: `{commit}`" + (f" (+{dirty} kaydedilmemiş değişiklik)" if dirty else ""),
        f"- Güç: {power}",
        f"- Taban: {baseline['date']} (`{baseline['commit']}`), {baseline['note']}",
        f"- **Sonuç: {'GEÇTİ' if verdict else 'KALDI'}**",
        "",
        "## Testler",
        "",
        "| Adım | Durum | Ayrıntı |",
        "|---|---|---|",
        *[f"| {n} | {'✓' if ok else '✗'} | {d} |" for n, ok, d in steps],
        "",
        "## Ölçümler (taban ile)",
        "",
        "| Ölçüm | Taban | Şimdi | Durum | Not |",
        "|---|---|---|---|---|",
        *[f"| {n} | {fmt(b)} | {fmt(c)} | {mark[s]} | {note} |" for n, b, c, s, note in rows],
        "",
        "Ham çıktılar bu klasördedir: pytest.txt, flutter_*.txt, bench.txt, bench_summary.json, quality_*.",
        "",
    ]
    with open(os.path.join(out, "REGRESSION.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    history = os.path.join(EVIDENCE, "history.csv")
    new = not os.path.exists(history)
    cats = (bench or {}).get("by_profile_category", {})
    speed = lambda k: ((cats.get(k) or {}).get("render_time") or {}).get("mean")
    with open(history, "a", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        if new:
            w.writerow(["tarih", "commit", "backend_gecti", "flutter_gecti/kaldi", "guc", "upper_s", "lower_s",
                        "overall_s", "onizleme_s", "basari", "ssim", "lpips", "sonuc"])
        w.writerow([stamp, commit, py["passed"], flutter_line, power, speed("full/upper"), speed("full/lower"),
                    speed("full/overall"), speed("preview/upper"), ((bench or {}).get("success_rate") or {}).get("rate"),
                    ((quality or {}).get("ssim") or {}).get("mean"), ((quality or {}).get("lpips_alex") or {}).get("mean"),
                    "gecti" if verdict else "kaldi"])

    print("\n" + "\n".join(lines), flush=True)
    print(f"Kaydedildi: {out}", flush=True)
    return 0 if verdict else 1


if __name__ == "__main__":
    sys.exit(main())
