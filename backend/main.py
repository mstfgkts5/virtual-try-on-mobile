import asyncio
import base64
import io
import os
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image, UnidentifiedImageError

import spin_frames
from spin_jobs import SpinJobManager

sys.stdout.reconfigure(encoding="utf-8")  # Windows konsolunda Türkçe log'lar için

MAX_UPLOAD_BYTES = 15 * 1024 * 1024
engine = None  # CatVTONEngine, sunucu açılırken yüklenir
engine_error = None
spin_manager = None  # SpinJobManager, model yüklenince kurulur


@asynccontextmanager
async def lifespan(_: FastAPI):
    global engine, engine_error, spin_manager
    try:
        from engine import CatVTONEngine
        print("[SeeItOn] CatVTON modeli GPU'ya yükleniyor...")
        engine = await asyncio.to_thread(
            CatVTONEngine,
            int(os.getenv("TRYON_WIDTH", "576")),
            int(os.getenv("TRYON_HEIGHT", "768")),
        )
        print(f"[SeeItOn] Model hazır: {engine.gpu_info()}")

        def run_frame(person, garment, category):
            out = engine.run(person, garment, category)
            return out.image, out.render_time_sec

        spin_manager = SpinJobManager(run_frame, engine.is_back_view, interpolate=engine.interpolate)
    except Exception as e:
        engine_error = str(e)
        print(f"[HATA] Model yüklenemedi: {e}")
    yield


app = FastAPI(
    title="SeeItOn - Local Try-On Backend",
    description="CatVTON ile yerel GPU üzerinde üst, alt ve tam kıyafet sanal deneme.",
    version="4.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {"status": "online", "service": "SeeItOn", "engine": "CatVTON (local GPU)"}


@app.get("/health")
def health():
    if engine is None:
        return {"status": "loading" if engine_error is None else "error", "detail": engine_error}
    return {"status": "ok", "engine": "CatVTON", "gpu": engine.gpu_info()}


async def _read_image(upload: UploadFile, label: str) -> Image.Image:
    data = await upload.read()
    if not data:
        raise HTTPException(status_code=400, detail=f"{label} boş yüklendi.")
    if len(data) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail=f"{label} 15 MB sınırını aşıyor.")
    try:
        image = Image.open(io.BytesIO(data))
        image.load()
        return image
    except UnidentifiedImageError:
        raise HTTPException(status_code=400, detail=f"{label} geçerli bir görsel değil.")


@app.post("/api/v1/tryon")
async def process_tryon(
    person_image: UploadFile = File(...),
    garment_image: UploadFile = File(...),
    category: str = Form("upper"),
    steps: int = Form(15),
    seed: int = Form(42),
):
    if engine is None:
        raise HTTPException(status_code=503, detail=engine_error or "Model henüz yükleniyor, birazdan tekrar deneyin.")

    try:
        engine.normalize_category(category)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    if not 10 <= steps <= 50:
        raise HTTPException(status_code=400, detail="steps 10 ile 50 arasında olmalı.")

    person = await _read_image(person_image, "Kişi fotoğrafı")
    garment = await _read_image(garment_image, "Kıyafet fotoğrafı")

    print(f"[SeeItOn] İstek -> kategori: {category}, adım: {steps}")
    try:
        output = await asyncio.to_thread(engine.run, person, garment, category, steps, 2.5, seed)
    except Exception as e:
        print(f"[HATA] Çıkarım hatası: {e}")
        raise HTTPException(status_code=500, detail=f"Model çalıştırılamadı: {e}")

    print(f"[SeeItOn] Tamamlandı ({output.render_time_sec} sn)")
    # Kırpılmış kişi fotoğrafı da dönülür; uygulama önce/sonra karşılaştırmasını
    # orijinal (kırpılmamış) fotoğrafla yaparsa iki görsel üst üste oturmaz
    return {
        "image_base64": _encode(output.image, "PNG"),
        "person_base64": _encode(output.person, "JPEG"),
        "category": output.category,
        "render_time": output.render_time_sec,
        "width": output.image.width,
        "height": output.image.height,
    }


def _require_engine() -> None:
    if engine is None or spin_manager is None:
        raise HTTPException(status_code=503, detail=engine_error or "Model henüz yükleniyor, birazdan tekrar deneyin.")


@app.post("/api/v1/spin")
async def start_spin(
    video: UploadFile = File(...),
    garment_front: UploadFile = File(...),
    garment_back: UploadFile | None = File(None),
    category: str = Form("upper"),
    frames: int = Form(8),
):
    """360° dönüş: videodan `frames` kare alınır, her biri sırayla giydirilir; iş numarası döner."""
    _require_engine()
    try:
        engine.normalize_category(category)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    if not 4 <= frames <= 12:
        raise HTTPException(status_code=400, detail="frames 4 ile 12 arasında olmalı.")

    data = await video.read()
    if not data:
        raise HTTPException(status_code=400, detail="Video boş yüklendi.")
    if len(data) > spin_frames.MAX_VIDEO_BYTES:
        raise HTTPException(status_code=400, detail="Video 60 MB sınırını aşıyor.")
    front = (await _read_image(garment_front, "Kıyafet ön görseli")).convert("RGB")
    back = (await _read_image(garment_back, "Kıyafet arka görseli")).convert("RGB") if garment_back else None
    try:
        people = await asyncio.to_thread(spin_frames.extract_frames, data, frames)
    except spin_frames.VideoError as e:
        raise HTTPException(status_code=400, detail=str(e))

    job_id = spin_manager.submit(people, front, back, category)
    print(f"[SeeItOn] Dönüş işi {job_id[:8]} -> {len(people)} kare, kategori: {category}, arka görsel: {back is not None}")
    return {"job_id": job_id, "total": len(people)}


@app.get("/api/v1/spin/{job_id}")
def spin_status(job_id: str, since: int = 0):
    _require_engine()
    try:
        s = spin_manager.status(job_id, since)
    except KeyError:
        raise HTTPException(status_code=404, detail="Dönüş işi bulunamadı.")
    s["frames"] = [
        {"index": f["index"], "view": f["view"], "image_base64": _encode(f["image"], "PNG"), "render_time": f["render_time"]}
        for f in s["frames"]
    ]
    return s


@app.delete("/api/v1/spin/{job_id}")
def cancel_spin(job_id: str):
    _require_engine()
    try:
        spin_manager.cancel(job_id)
    except KeyError:
        raise HTTPException(status_code=404, detail="Dönüş işi bulunamadı.")
    print(f"[SeeItOn] Dönüş işi {job_id[:8]} iptal edildi")
    return {"status": "cancelled"}


def _encode(image: Image.Image, fmt: str) -> str:
    buffer = io.BytesIO()
    image.save(buffer, format=fmt, **({"quality": 95} if fmt == "JPEG" else {}))
    return base64.b64encode(buffer.getvalue()).decode("ascii")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000)
