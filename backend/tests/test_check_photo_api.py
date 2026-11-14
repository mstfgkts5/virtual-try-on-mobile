import io

import pytest
from fastapi.testclient import TestClient
from PIL import Image

import main


def png():
    buf = io.BytesIO()
    Image.new("RGB", (8, 8), "red").save(buf, format="PNG")
    return buf.getvalue()


class FakeEngine:
    def __init__(self):
        self.calls = []

    @staticmethod
    def normalize_category(category):
        if category not in ("upper", "lower", "overall"):
            raise ValueError("Geçersiz kategori")
        return category

    def check_photo(self, person, category):
        self.calls.append(category)
        return ["person_small"]


@pytest.fixture
def client(monkeypatch):
    eng = FakeEngine()
    monkeypatch.setattr(main, "engine", eng)
    return TestClient(main.app), eng


def test_check_photo_returns_warnings(client):
    c, eng = client
    r = c.post("/api/v1/check_photo", files={"person_image": ("p.png", png(), "image/png")}, data={"category": "lower"})
    assert r.status_code == 200, r.text
    assert r.json() == {"warnings": ["person_small"]}
    assert eng.calls == ["lower"]


def test_check_photo_rejects_bad_category(client):
    c, _ = client
    r = c.post("/api/v1/check_photo", files={"person_image": ("p.png", png(), "image/png")}, data={"category": "hat"})
    assert r.status_code == 400


def test_check_photo_while_loading(monkeypatch):
    monkeypatch.setattr(main, "engine", None)
    r = TestClient(main.app).post("/api/v1/check_photo", files={"person_image": ("p.png", png(), "image/png")})
    assert r.status_code == 503
