import numpy as np
from PIL import Image

from person_crop import canvas_of, fit_box, person_bbox


def test_small_person_is_cropped_to_3x4_box_inside_canvas():
    # Kadrajın ortasında küçük bir kişi (gerçek fotoğraf gibi)
    box = fit_box((500, 400, 700, 1000), 1152, 1536)
    assert box is not None
    l, t, r, b = box
    assert 0 <= l and 0 <= t and r <= 1152 and b <= 1536
    assert abs((r - l) / (b - t) - 0.75) < 0.01
    assert l <= 500 and r >= 700 and t <= 400 and b >= 1000  # kişi kutunun içinde


def test_person_filling_frame_is_not_cropped():
    # VITON-HD gibi kişi kadrajı dolduruyor: davranış eskisiyle aynı kalmalı
    assert fit_box((40, 20, 540, 760), 576, 768) is None


def test_box_is_shifted_inside_when_person_at_edge():
    l, t, r, b = fit_box((0, 900, 150, 1400), 1152, 1536)
    assert l == 0 and b <= 1536


def test_person_bbox():
    labels = np.zeros((100, 80), dtype=np.uint8)
    labels[20:90, 30:50] = 5
    assert person_bbox(labels) == (30, 20, 50, 90)
    assert person_bbox(np.zeros((10, 10), dtype=np.uint8)) is None


def test_canvas_is_3x4_and_capped():
    c = canvas_of(Image.new("RGB", (3000, 4000)), 576, 768)
    assert c.size == (1152, 1536)
    c = canvas_of(Image.new("RGB", (400, 400)), 576, 768)
    assert c.size == (576, 768)  # küçük fotoğraf en az model çözünürlüğüne çıkar



def test_trim_garment_removes_empty_background():
    from person_crop import trim_garment
    img = Image.new("RGB", (600, 800), (230, 230, 230))
    img.paste((40, 80, 160), (150, 200, 450, 600))
    out = trim_garment(img)
    assert out.width < 400 and out.height < 500
    assert out.width >= 300 and out.height >= 400


def test_match_colors_restores_saturation_only_on_cloth():
    from person_crop import match_colors
    garment = Image.new("RGB", (100, 120), (235, 235, 235))
    garment.paste((20, 60, 200), (20, 20, 80, 100))  # canlı mavi kıyafet
    res = np.zeros((80, 60, 3), dtype=np.uint8)
    res[:] = (90, 120, 60)  # arka plan (yeşil)
    res[20:60, 15:45] = (120, 130, 150)  # soluk gri-mavi kıyafet
    cloth = np.zeros((80, 60), dtype=bool)
    cloth[20:60, 15:45] = True
    out = np.asarray(match_colors(Image.fromarray(res), cloth, garment)).astype(int)
    r, g, b = out[40, 30]
    assert b - r > 60  # belirgin şekilde maviye döndü
    assert tuple(out[5, 5]) == (90, 120, 60)  # kıyafet dışı değişmedi



def test_garment_foreground_on_real_navy_trousers():
    # Gerçek örnek: lacivert pantolon, kenarlara doğru koyulaşan gri stüdyo fonu.
    # Eski köşe rengi yöntemi fonu da kıyafet sayıyor, ortalama griye kayıyordu (renk düzeltme lacivert yerine gri)
    import os

    import pytest
    from person_crop import garment_foreground

    path = os.path.join(os.path.dirname(__file__), "..", "..", "see_it_on", "assets", "images", "garments", "trousers-m.jpg")
    if not os.path.exists(path):
        pytest.skip("örnek kıyafet görseli yok")
    img = Image.open(path).convert("RGB")
    fg = garment_foreground(img)
    r, g, b = np.asarray(img)[fg].mean(axis=0)
    assert max(r, g, b) < 70 and b > r  # koyu ve mavimsi: fon karışmadı


def test_person_bbox_ignores_small_far_away_blobs():
    # Ana kişi altta; gökyüzünde yanlışlıkla "kişi" sanılan küçük bir heykel parçası
    labels = np.zeros((400, 300), dtype=np.uint8)
    labels[180:400, 100:200] = 5
    labels[20:50, 230:260] = 13
    assert person_bbox(labels) == (100, 180, 200, 400)


def test_limit_mask_drops_far_regions_but_keeps_the_person():
    from person_crop import limit_mask_to_person
    labels = np.zeros((400, 300), dtype=np.uint8)
    labels[180:400, 100:200] = 5
    labels[20:50, 230:260] = 13
    m = np.zeros((400, 300), dtype=np.uint8)
    m[180:400, 90:210] = 255  # kişinin maskesi (biraz geniş)
    m[20:60, 220:270] = 255  # uzaktaki yanlış maske parçası
    out = np.array(limit_mask_to_person(Image.fromarray(m), labels))
    assert out[300, 95] == 255 and out[300, 150] == 255  # kişi ve hemen yanı kaldı
    assert out[40, 245] == 0  # uzaktaki parça atıldı
