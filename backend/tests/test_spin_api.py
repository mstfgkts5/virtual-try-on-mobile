import base64
import io

import pytest
from fastapi.testclient import TestClient
from PIL import Image

import main
import spin_frames
from spin_jobs import SpinJobManager
from tests.videos import make_video


class FakeEngine:
    @staticmethod
    def normalize_category(category):
        if category not in ("upper", "lower", "overall"):
            raise ValueError(f"Geçersiz kategori: '{category}'.")
        return category


def png_bytes(color="red"):
    buf = io.BytesIO()
    Image.new("RGB", (8, 8), color).save(buf, format="PNG")
    return buf.getvalue()


@pytest.fixture
def api(monkeypatch):
    manager = SpinJobManager(lambda p, g, c: (p.copy(), 1.0), lambda p: False, start_thread=False)
    monkeypatch.setattr(main, "engine", FakeEngine())
    monkeypatch.setattr(main, "spin_manager", manager)
    return TestClient(main.app), manager


def post(client, video=None, frames=None, category="upper", back=True):
    files = {
        "video": ("turn.mp4", video if video is not None else make_video(64, 112, 2), "video/mp4"),
        "garment_front": ("front.png", png_bytes(), "image/png"),
    }
    if back:
        files["garment_back"] = ("back.png", png_bytes("blue"), "image/png")
    data = {"category": category}
    if frames is not None:
        data["frames"] = str(frames)
    return client.post("/api/v1/spin", files=files, data=data)


def test_post_returns_job_and_total(api):
    client, _ = api
    r = post(client)
    assert r.status_code == 200, r.text
    assert r.json()["total"] == 12 and r.json()["job_id"]


def test_post_without_back_image(api):
    client, _ = api
    assert post(client, back=False).status_code == 200


def test_post_frames_param(api):
    client, _ = api
    assert post(client, frames=4).json()["total"] == 4
    assert post(client, frames=3).status_code == 400
    assert post(client, frames=16).json()["total"] == 16
    assert post(client, frames=17).status_code == 400


def test_post_bad_category_400(api):
    client, _ = api
    assert post(client, category="hat").status_code == 400


def test_post_bad_video_400_with_hint(api):
    client, _ = api
    r = post(client, video=b"not a video")
    assert r.status_code == 400
    assert "En Uyumlu" in r.json()["detail"]


def test_post_too_large_400(api, monkeypatch):
    client, _ = api
    monkeypatch.setattr(spin_frames, "MAX_VIDEO_BYTES", 1000)
    r = post(client, video=b"x" * 2000)
    assert r.status_code == 400


def test_post_engine_missing_503(api, monkeypatch):
    client, _ = api
    monkeypatch.setattr(main, "engine", None)
    assert post(client).status_code == 503


def test_get_returns_base64_frames_since(api):
    client, manager = api
    job = post(client, frames=4).json()["job_id"]
    manager.step()
    manager.step()
    r = client.get(f"/api/v1/spin/{job}", params={"since": 1})
    body = r.json()
    assert body["status"] == "running" and body["done"] == 2 and body["total"] == 4
    assert [f["index"] for f in body["frames"]] == [1]
    frame = body["frames"][0]
    assert frame["view"] == "front" and frame["render_time"] == 1.0 and frame["kind"] == "key"
    decoded = Image.open(io.BytesIO(base64.b64decode(frame["image_base64"])))
    assert decoded.format == "JPEG"  # kareler hafif olsun diye JPEG


def test_get_unknown_404(api):
    client, _ = api
    assert client.get("/api/v1/spin/nope").status_code == 404


def test_delete_unknown_404(api):
    client, _ = api
    assert client.delete("/api/v1/spin/nope").status_code == 404


def test_delete_cancels(api):
    client, _ = api
    job = post(client).json()["job_id"]
    assert client.delete(f"/api/v1/spin/{job}").json() == {"status": "cancelled"}
    assert client.get(f"/api/v1/spin/{job}").json()["status"] == "cancelled"
