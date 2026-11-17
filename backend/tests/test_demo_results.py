"""Çevrimdışı demo listesi: uygulamadaki her hazır manken ve örnek kıyafet kapsanıyor mu."""
import os
import re

import make_demo_results as demo

HOME = os.path.join(demo.ROOT, "see_it_on", "lib", "screens", "home_screen.dart")


def test_every_pair_uses_existing_assets():
    pairs = list(demo.all_pairs())
    assert len(pairs) == 8 * 5 + 4 * 3 + 4 * 2
    for m, g, _ in pairs:
        assert os.path.exists(os.path.join(demo.ASSETS, "mannequins", m + ".jpg"))
        assert os.path.exists(os.path.join(demo.ASSETS, "garments", g + ".jpg"))


def test_lists_match_the_app():
    src = open(HOME, encoding="utf-8").read()
    mannequins = re.findall(r"\{'id': '([wm]-\w+)', 'info'", src)
    garments = re.findall(r"\{'id': '([\w-]+)', 'category': '(upper|lower)'\}", src)
    assert mannequins == demo.MANNEQUINS
    assert sorted(g for g, c in garments if c == "upper") == sorted(demo.UPPER)
    assert sorted(g for g, c in garments if c == "lower") == sorted(demo.LOWER["w"] + demo.LOWER["m"])


def test_lower_garments_follow_mannequin_gender():
    for m, g, cat in demo.all_pairs():
        if cat == "lower":
            assert g in demo.LOWER[m[0]]


def test_rejected_pairs_are_left_out():
    kept = {(m, g) for m, g, _ in demo.pairs()}
    assert len(kept) == 60 - len(demo.REJECTED)
    assert not kept & set(demo.REJECTED)
    assert set(demo.REJECTED) <= {(m, g) for m, g, _ in demo.all_pairs()}
