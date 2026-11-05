"""360° dönüş API'si için smoke testi (backend çalışırken).

Kullanım:
    backend\\venv\\Scripts\\python.exe tests\\api_spin.py --video dönüş.mp4 --front ön.png [--back arka.png]
    backend\\venv\\Scripts\\python.exe tests\\api_spin.py --from-images klasör --front ön.png [--back arka.png]
--from-images: klasördeki görsellerden (ada göre sıralı) her biri 1 sn süren bir MP4 üretir.
"""
import argparse
import glob
import io
import os
import sys
import time

sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "backend"))

import av  # noqa: E402
import httpx  # noqa: E402
import numpy as np  # noqa: E402
from PIL import Image  # noqa: E402


def video_from_images(folder: str, fps: int = 10) -> bytes:
    paths = sorted(glob.glob(os.path.join(folder, "*.png")) + glob.glob(os.path.join(folder, "*.jpg")))
    buf = io.BytesIO()
    c = av.open(buf, "w", format="mp4")
    s = c.add_stream("libx264", rate=fps)
    s.width, s.height, s.pix_fmt = 768, 1024, "yuv420p"
    for p in paths:
        arr = np.asarray(Image.open(p).convert("RGB").resize((768, 1024)))
        for _ in range(fps):
            for pkt in s.encode(av.VideoFrame.from_ndarray(arr, format="rgb24")):
                c.mux(pkt)
    for pkt in s.encode():
        c.mux(pkt)
    c.close()
    print(f"{len(paths)} görselden {len(paths)} sn'lik video üretildi")
    return buf.getvalue()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--video")
    ap.add_argument("--from-images")
    ap.add_argument("--front", required=True)
    ap.add_argument("--back")
    ap.add_argument("--frames", type=int, default=4)
    ap.add_argument("--url", default="http://127.0.0.1:8000")
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "output", "spin"))
    a = ap.parse_args()
    data = open(a.video, "rb").read() if a.video else video_from_images(a.from_images)
    files = {"video": ("turn.mp4", data, "video/mp4"), "garment_front": ("front.png", open(a.front, "rb").read())}
    if a.back:
        files["garment_back"] = ("back.png", open(a.back, "rb").read())
    start = time.perf_counter()
    r = httpx.post(f"{a.url}/api/v1/spin", files=files, data={"frames": str(a.frames)}, timeout=120)
    r.raise_for_status()
    job, total = r.json()["job_id"], r.json()["total"]
    print(f"iş {job[:8]} başladı, {total} kare")
    os.makedirs(a.out, exist_ok=True)
    since = 0
    while True:
        s = httpx.get(f"{a.url}/api/v1/spin/{job}", params={"since": since}, timeout=30).json()
        for f in s["frames"]:
            import base64
            Image.open(io.BytesIO(base64.b64decode(f["image_base64"]))).save(os.path.join(a.out, f"frame_{f['index']}.png"))
            print(f"  kare {f['index']} ({f['view']}) {f['render_time']} sn — {time.perf_counter() - start:.0f} sn'de geldi")
            since = f["index"] + 1
        if s["status"] not in ("queued", "running"):
            print("durum:", s["status"], s["error"] or "")
            break
        time.sleep(3)


if __name__ == "__main__":
    main()
