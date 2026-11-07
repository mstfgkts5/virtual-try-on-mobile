import io
import types

import pytest
from fastapi.testclient import TestClient
from PIL import Image

import main


def png(color="red"):
    buf = io.BytesIO()
    Image.new("RGB", (8, 8), color).save(buf, format="PNG")
    return buf.getvalue()


class RecordingEngine:
    def __init__(self):
        self.calls = []

    @staticmethod
    def normalize_category(category):
        if category not in ("upper", "lower", "overall"):
            raise ValueError("Geçersiz kategori")
        return category

    def run(self, person, garment, category, steps=15, guidance_scale=2.5, seed=42, size=None):
        self.calls.append({"steps": steps, "size": size})
        img = Image.new("RGB", size or (576, 768), "blue")
        return types.SimpleNamespace(image=img, person=img, category=category, render_time_sec=0.5)


@pytest.fixture
def client(monkeypatch):
    eng = RecordingEngine()
    monkeypatch.setattr(main, "engine", eng)
    return TestClient(main.app), eng


def post(c, **data):
    files = {"person_image": ("p.png", png(), "image/png"), "garment_image": ("g.png", png("blue"), "image/png")}
    return c.post("/api/v1/tryon", files=files, data=data)


def test_preview_uses_fast_profile(client):
    c, eng = client
    r = post(c, category="upper", preview="true")
    assert r.status_code == 200, r.text
    # Canlı deneme: 10 adım · 384x512 (ölçüm: ~2,2 sn, şarjda)
    assert eng.calls[-1] == {"steps": 10, "size": (384, 512)}
    assert r.json()["width"] == 384 and r.json()["preview"] is True


def test_full_quality_by_default(client):
    c, eng = client
    r = post(c, category="upper")
    assert r.status_code == 200
    assert eng.calls[-1] == {"steps": 15, "size": None}
    assert r.json()["preview"] is False
