"""CatVTON tabanlı yerel sanal deneme motoru.

Model bir kez GPU'ya yüklenir ve tüm istekler aynı pipeline'ı kullanır.
CatVTON kaynak kodu ai/CatVTON klasöründen import edilir.
"""
import os
import sys
import threading
import time
from dataclasses import dataclass

import numpy as np
import torch
from PIL import Image, ImageFilter, ImageOps

CATVTON_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "ai", "CatVTON"))
sys.path.insert(0, CATVTON_DIR)

from diffusers.image_processor import VaeImageProcessor  # noqa: E402
from huggingface_hub import snapshot_download  # noqa: E402
from model.cloth_masker import AutoMasker  # noqa: E402  # type: ignore
from model.pipeline import CatVTONPipeline  # noqa: E402  # type: ignore
from utils import resize_and_crop, resize_and_padding  # noqa: E402  # type: ignore

from spin_frames import BACK_FACE_RATIO, face_ratio  # noqa: E402

BASE_MODEL = "booksforcharlie/stable-diffusion-inpainting"
CATVTON_MODEL = "zhengchong/CatVTON"

# Uygulamanın gönderdiği kategori adları -> CatVTON maske tipleri
CATEGORY_ALIASES = {
    "upper": "upper", "upper_body": "upper", "top": "upper",
    "lower": "lower", "lower_body": "lower", "bottom": "lower",
    "overall": "overall", "full": "overall", "dresses": "overall",
}


@dataclass
class TryOnOutput:
    image: Image.Image
    person: Image.Image  # Modele giren 3:4 kırpılmış kişi fotoğrafı (önce/sonra karşılaştırması için)
    mask: Image.Image
    category: str
    render_time_sec: float


class CatVTONEngine:
    def __init__(self, width: int = 768, height: int = 1024):
        if not torch.cuda.is_available():
            raise RuntimeError("CUDA bulunamadı. CatVTON için NVIDIA GPU gerekli.")

        self.width = width
        self.height = height
        self.device = "cuda"
        self._lock = threading.Lock()  # Tek GPU: istekler sırayla işlenir

        repo_path = snapshot_download(CATVTON_MODEL)
        self.pipeline = CatVTONPipeline(
            base_ckpt=BASE_MODEL,
            attn_ckpt=repo_path,
            attn_ckpt_version="mix",
            weight_dtype=torch.bfloat16,
            use_tf32=True,
            skip_safety_check=True,  # 8 GB VRAM'de yer açmak için
            device=self.device,
        )
        self.automasker = AutoMasker(
            densepose_ckpt=os.path.join(repo_path, "DensePose"),
            schp_ckpt=os.path.join(repo_path, "SCHP"),
            device=self.device,
        )
        self.mask_processor = VaeImageProcessor(
            vae_scale_factor=8, do_normalize=False, do_binarize=True, do_convert_grayscale=True
        )

    @staticmethod
    def normalize_category(category: str) -> str:
        key = (category or "").strip().lower()
        if key not in CATEGORY_ALIASES:
            raise ValueError(f"Geçersiz kategori: '{category}'. upper, lower veya overall olmalı.")
        return CATEGORY_ALIASES[key]

    def gpu_info(self) -> dict:
        free, total = torch.cuda.mem_get_info()
        return {
            "name": torch.cuda.get_device_name(0),
            "vram_total_mb": total // (1024 * 1024),
            "vram_free_mb": free // (1024 * 1024),
        }

    def run(
        self,
        person: Image.Image,
        garment: Image.Image,
        category: str,
        steps: int = 30,
        guidance_scale: float = 2.5,
        seed: int = 42,
    ) -> TryOnOutput:
        mask_type = self.normalize_category(category)

        # Telefon fotoğraflarındaki EXIF dönüşünü uygula, yoksa görsel yan gelir
        person = ImageOps.exif_transpose(person).convert("RGB")
        garment = ImageOps.exif_transpose(garment).convert("RGB")
        person = resize_and_crop(person, (self.width, self.height))
        garment = resize_and_padding(garment, (self.width, self.height))

        with self._lock:
            start = time.perf_counter()
            mask = self.automasker(person, mask_type)["mask"]
            mask = self.mask_processor.blur(mask, blur_factor=9)

            generator = torch.Generator(device=self.device).manual_seed(seed) if seed >= 0 else None
            result = self.pipeline(
                image=person,
                condition_image=garment,
                mask=mask,
                num_inference_steps=steps,
                guidance_scale=guidance_scale,
                height=self.height,
                width=self.width,
                generator=generator,
            )[0]
            torch.cuda.synchronize()
            elapsed = time.perf_counter() - start

        # Maske dışındaki alanları (yüz, arka plan) orijinal fotoğraftan geri al
        result = self._repaint(person, mask, result)
        return TryOnOutput(
            image=result, person=person, mask=mask, category=mask_type, render_time_sec=round(elapsed, 2)
        )

    def face_ratio_of(self, person: Image.Image) -> float:
        """Kişi fotoğrafında yüz piksellerinin oranı (SCHP-LIP); arka kare tanıma için."""
        person = resize_and_crop(ImageOps.exif_transpose(person).convert("RGB"), (self.width, self.height))
        with self._lock:
            lip = self.automasker.process_schp_lip(person)
        return face_ratio(np.array(lip))

    def is_back_view(self, person: Image.Image) -> bool:
        """Yüz görünmüyorsa kişi arkası dönük sayılır; 360° dönüşte arka kıyafet görseli seçilir."""
        return self.face_ratio_of(person) < BACK_FACE_RATIO

    @staticmethod
    def _repaint(person: Image.Image, mask: Image.Image, result: Image.Image) -> Image.Image:
        # Maske önce genişletilir, sonra az yumuşatılır; aksi halde kıyafet kenarında
        # eski fotoğraf yeni kıyafetle karışıp "hayalet" iz bırakıyor
        grow = result.size[1] // 64 | 1
        soft = mask.convert("L").filter(ImageFilter.MaxFilter(grow)).filter(ImageFilter.GaussianBlur(grow // 3))
        soft_mask = np.array(soft)[..., None] / 255.0
        blended = np.array(person) * (1 - soft_mask) + np.array(result) * soft_mask
        return Image.fromarray(blended.astype(np.uint8))
