import asyncio
import io
import os
import time
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from PIL import Image
from huggingface_hub import login

# Token artık kodun içinde değil, .env dosyasından / ortam değişkeninden okunuyor (güvenlik için).
# backend klasöründeki .env dosyasına tek satır yazın:  HF_TOKEN=hf_...
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    print("[UYARI] python-dotenv kurulu değil: pip install python-dotenv")

HF_TOKEN = os.getenv("HF_TOKEN", "")
if HF_TOKEN:
    try:
        login(token=HF_TOKEN)
    except Exception as e:
        print(f"[UYARI] Hugging Face login uyarısı: {e}")
else:
    print("[UYARI] HF_TOKEN ayarlanmamış, anonim kota ile devam ediliyor.")

app = FastAPI(
    title="SeeItOn - Bulletproof AI Backend",
    description="Stable architecture powered exclusively by IDM-VTON Universal Engine.",
    version="3.5.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

try:
    from gradio_client import Client, handle_file
    GRADIO_AVAILABLE = True
except ImportError:
    GRADIO_AVAILABLE = False


@app.get("/")
def root():
    return {
        "status": "online",
        "service": "SeeItOn Stable Engine",
        "engine": "IDM-VTON Universal Pipeline"
    }


@app.get("/health")
def health():
    return {"status": "ok"}


def optimize_image(image_bytes: bytes, max_width: int = 768, max_height: int = 1024) -> bytes:
    img = Image.open(io.BytesIO(image_bytes))
    if img.mode not in ("RGB", "RGBA"):
        img = img.convert("RGBA" if "A" in img.getbands() else "RGB")
    img.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)

    buffer = io.BytesIO()
    if img.mode == "RGBA":
        img.save(buffer, format="PNG", optimize=True)
    else:
        img.save(buffer, format="JPEG", quality=90, optimize=True)
    return buffer.getvalue()


def _run_idm_vton(person_path: str, garment_path: str, category: str):
    """Bloklayan Space çağrısı. Ayrı thread'de çalıştırılır ki sunucu donmasın."""
    client = Client("yisol/IDM-VTON")

    if category == "lower_body":
        garment_description = "A pair of trousers, pants, lower body garment"
        is_crop_val = True
    elif category == "dresses":
        garment_description = "Full body dress gown"
        is_crop_val = False
    else:
        garment_description = "Virtual try-on high quality top garment, shirt, jacket"
        is_crop_val = False

    return client.predict(
        dict={"background": handle_file(person_path), "layers": [], "composite": None},
        garm_img=handle_file(garment_path),
        garment_des=garment_description,
        is_checked=True,
        is_checked_crop=is_crop_val,
        denoise_steps=30,
        seed=42,
        api_name="/tryon"
    )


@app.post("/api/v1/tryon")
async def process_tryon(
    person_image: UploadFile = File(...),
    garment_image: UploadFile = File(...),
    category: str = Form("upper_body"),
    fit_type: str = Form("Tailored"),
    lock_pose: str = Form("false"),
    auto_clean_bg: str = Form("true")
):
    person_path, garment_path = None, None
    try:
        person_bytes = await person_image.read()
        garment_bytes = await garment_image.read()

        if not person_bytes or not garment_bytes:
            raise HTTPException(status_code=400, detail="Eksik fotoğraf yüklendi.")

        os.makedirs("temp", exist_ok=True)
        timestamp = int(time.time() * 1000)
        person_path = f"temp/person_{timestamp}.jpg"
        garment_path = f"temp/garment_{timestamp}.jpg"

        with open(person_path, "wb") as f:
            f.write(optimize_image(person_bytes))
        with open(garment_path, "wb") as f:
            f.write(optimize_image(garment_bytes))

        if not GRADIO_AVAILABLE:
            raise HTTPException(status_code=500, detail="gradio_client kütüphanesi eksik.")

        print(f"\n[SeeItOn Engine] İstek İşleniyor -> Kategori: {category}")
        print("[SeeItOn Engine] IDM-VTON çalışıyor (30-120 sn sürebilir)...")

        result = await asyncio.to_thread(_run_idm_vton, person_path, garment_path, category)

        output_image_path = result[0] if isinstance(result, (list, tuple)) else result

        if output_image_path and os.path.exists(output_image_path):
            with open(output_image_path, "rb") as f:
                output_bytes = f.read()

            _safe_remove(person_path, garment_path)
            print("[SeeItOn Engine] İşlem BAŞARILI!")
            return Response(content=output_bytes, media_type="image/png")
        else:
            raise Exception("Yapay zeka modeli görseli oluşturamadı.")

    except HTTPException:
        _safe_remove(person_path, garment_path)
        raise
    except Exception as api_err:
        _safe_remove(person_path, garment_path)
        print(f"\n[HATA] Sunucu İşlem Hatası: {str(api_err)}\n")
        raise HTTPException(status_code=503, detail=f"Sunucu hatası: {str(api_err)}")


def _safe_remove(*paths):
    for p in paths:
        try:
            if p and os.path.exists(p):
                os.remove(p)
        except Exception:
            pass


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)