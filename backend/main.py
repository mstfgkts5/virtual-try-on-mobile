import asyncio
import base64
import io
import os
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image, UnidentifiedImageError

sys.stdout.reconfigure(encoding="utf-8")  # Windows konsolunda Türkçe log'lar için

MAX_UPLOAD_BYTES = 15 * 1024 * 1024
engine = None  # CatVTONEngine, sunucu açılırken yüklenir
engine_error = None


@asynccontextmanager
async def lifespan(_: FastAPI):
    global engine, engine_error
    try:
        from engine import CatVTONEngine
        print("[SeeItOn] CatVTON modeli GPU'ya yükleniyor...")
        engine = await asyncio.to_thread(
            CatVTONEngine,
            int(os.getenv("TRYON_WIDTH", "768")),
            int(os.getenv("TRYON_HEIGHT", "1024")),
        )
        print(f"[SeeItOn] Model hazır: {engine.gpu_info()}")
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
    steps: int = Form(30),
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


def _encode(image: Image.Image, fmt: str) -> str:
    buffer = io.BytesIO()
    image.save(buffer, format=fmt, **({"quality": 95} if fmt == "JPEG" else {}))
    return base64.b64encode(buffer.getvalue()).decode("ascii")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000)
