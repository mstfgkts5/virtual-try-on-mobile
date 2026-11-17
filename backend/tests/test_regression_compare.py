"""Haftalık regresyonun (tests/regression.py) çıktı okuma ve karşılaştırma kuralları."""
import copy
import importlib.util
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
_spec = importlib.util.spec_from_file_location("regression", os.path.join(ROOT, "tests", "regression.py"))
reg = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(reg)

with open(os.path.join(ROOT, "tests", "regression_baseline.json"), encoding="utf-8") as f:
    BASE = json.load(f)


def bench(upper=14.2, lower=14.6, overall=14.4, preview=1.2, rate=1.0, power="AC (şarjda)"):
    cat = lambda m: {"render_time": {"mean": m}}
    return {"power": power, "success_rate": {"rate": rate}, "by_profile_category": {
        "full/upper": cat(upper), "full/lower": cat(lower), "full/overall": cat(overall), "preview/upper": cat(preview)}}


def quality(ssim=0.86, lpips=0.141, ok=49):
    return {"pairs_requested": 50, "succeeded": ok, "ssim": {"mean": ssim}, "lpips_alex": {"mean": lpips}}


def status(rows):
    return {name: s for name, _, _, s, _ in rows}


def test_same_numbers_pass():
    rows = reg.compare(BASE, bench(), quality(), on_mains=True)
    assert all(s == "ok" for s in status(rows).values())


def test_slower_than_15_percent_fails():
    rows = reg.compare(BASE, bench(upper=14.19 * 1.2), quality(), on_mains=True)
    assert status(rows)["süre full/upper (s)"] == "fail"
    assert status(rows)["süre full/lower (s)"] == "ok"


def test_speed_not_compared_on_battery():
    rows = reg.compare(BASE, bench(upper=30.0), quality(), on_mains=False)
    assert status(rows)["süre full/upper (s)"] == "skip"


def test_quality_drop_and_failed_requests_fail():
    s = status(reg.compare(BASE, bench(rate=0.975), quality(ssim=0.84, lpips=0.16, ok=47), on_mains=True))
    assert s["başarı oranı"] == "fail"
    assert s["SSIM (yüksek iyi)"] == "fail"
    assert s["LPIPS (düşük iyi)"] == "fail"
    assert s["başarılı çift"] == "fail"


def test_one_failed_pair_is_tolerated():
    assert status(reg.compare(BASE, bench(), quality(ok=49), on_mains=True))["başarılı çift"] == "ok"


def test_missing_measurements_are_skipped_not_passed():
    rows = reg.compare(BASE, None, None, on_mains=True)
    assert {s for *_, s, _ in rows} == {"skip"}


def test_parsers():
    assert reg.parse_pytest("78 passed, 1 failed in 9.1s") == {"passed": 78, "failed": 1}
    assert reg.parse_pytest("79 passed in 7.9s") == {"passed": 79, "failed": 0}
    ok = "00:05 +192: x\n00:06 +193: All tests passed!"
    assert reg.parse_flutter_test(ok) == {"passed": 193, "failed": 0, "ok": True}
    bad = "00:06 +192 -1: Some tests failed."
    assert reg.parse_flutter_test(bad) == {"passed": 192, "failed": 1, "ok": False}
    assert reg.parse_flutter_test("derleme hatası")["ok"] is False
    assert reg.parse_flutter_analyze("No issues found! (ran in 3s)")["ok"] is True
    assert reg.parse_flutter_analyze("2 issues found. (ran in 44s)") == {"issues": 2, "ok": False}


def test_baseline_matches_reported_numbers():
    # Ara Rapor Bölüm 10.9 ile aynı sayılar
    assert BASE["speed_render_s"]["full/upper"] == 14.19
    assert BASE["quality"]["ssim"] == 0.8603 and BASE["quality"]["lpips"] == 0.1414
    b = copy.deepcopy(BASE)
    assert reg.compare(b, bench(), quality(), True) == reg.compare(BASE, bench(), quality(), True)
