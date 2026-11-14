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

from diffusers import DPMSolverMultistepScheduler  # noqa: E402
from diffusers.image_processor import VaeImageProcessor  # noqa: E402
from huggingface_hub import snapshot_download  # noqa: E402
from model.cloth_masker import AutoMasker  # noqa: E402  # type: ignore
from model.pipeline import CatVTONPipeline  # noqa: E402  # type: ignore
from utils import resize_and_crop, resize_and_padding  # noqa: E402  # type: ignore

from person_crop import (  # noqa: E402
    CLOTH_LABELS, canvas_of, fit_box, limit_mask_to_person, match_colors, person_bbox, trim_garment
)  # noqa: E402
from photo_check import assess_photo  # noqa: E402
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
        # DDIM (eta=1) yerine DPM-Solver++: az adımda aynı kalite. Ölçüm (2026-11-07, şarjda):
        # 576x768 · 8 adım 4,4 sn (DDIM 15 adım 8,2 sn); 384x512 · 3 adım 0,75 sn (DDIM 10 adım 1,9 sn)
        self.pipeline.noise_scheduler = DPMSolverMultistepScheduler.from_config(
            self.pipeline.noise_scheduler.config, algorithm_type="dpmsolver++", solver_order=2
        )
        self.automasker = AutoMasker(
            densepose_ckpt=os.path.join(repo_path, "DensePose"),
            schp_ckpt=os.path.join(repo_path, "SCHP"),
            device=self.device,
        )
        # 360° dönüş ara kareleri (RIFE, ~25 MB); yüklenemezse dönüş basit karışımla devam eder
        try:
            from interpolator import RifeInterpolator

            self.rife = RifeInterpolator.from_hub(self.device)
        except Exception as e:
            print(f"[SeeItOn] RIFE yüklenemedi, ara kareler karışımla üretilecek: {e}")
            self.rife = None
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
        steps: int = 8,
        guidance_scale: float = 2.5,
        seed: int = 42,
        size: tuple[int, int] | None = None,
        crop_person: bool = True,
        trim: bool = False,
        color_fix: bool | None = None,
    ) -> TryOnOutput:
        """`size` (genişlik, yükseklik) verilirse o çözünürlükte çalışır (canlı önizleme: 384x512).

        Tam kalitede (`size` yok) kişi kadrajda bulunur ve model kişinin etrafındaki 3:4 kutuda
        çalışır; sonuç yüksek çözünürlüklü fotoğrafa geri yapıştırılır (bkz. person_crop.py).
        """
        mask_type = self.normalize_category(category)
        width, height = size or (self.width, self.height)

        # Telefon fotoğraflarındaki EXIF dönüşünü uygula, yoksa görsel yan gelir
        person = ImageOps.exif_transpose(person).convert("RGB")
        garment = ImageOps.exif_transpose(garment).convert("RGB")
        garment_raw = garment
        if trim:
            garment = trim_garment(garment)
        garment = resize_and_padding(garment, (width, height))
        use_crop = crop_person
        if color_fix is None:
            # Tam sonuçta açık (+~0,3 sn): az adımda ve loş/sisli fotoğraflarda renkler soluyordu
            color_fix = size is None
        canvas = canvas_of(person, max(width, self.width), max(height, self.height)) if use_crop else resize_and_crop(person, (width, height))

        with self._lock:
            start = time.perf_counter()
            box = None
            if use_crop:
                small = canvas.resize((width, height), Image.LANCZOS)
                bbox = person_bbox(np.array(self.automasker.process_schp_lip(small)))
                if bbox is not None:
                    sx, sy = canvas.width / width, canvas.height / height
                    bbox = (bbox[0] * sx, bbox[1] * sy, bbox[2] * sx, bbox[3] * sy)
                    box = fit_box(bbox, canvas.width, canvas.height, aspect=width / height)
            region = canvas.crop(box) if box else canvas
            model_in = region.resize((width, height), Image.LANCZOS) if region.size != (width, height) else region

            parsed = self.automasker(model_in, mask_type)
            # Arka plandaki heykel/afiş gibi yanlış "kişi" parçalarına model bir şey çizmesin
            mask = limit_mask_to_person(parsed["mask"], np.array(parsed["schp_lip"]))
            mask = self.mask_processor.blur(mask, blur_factor=9)

            generator = torch.Generator(device=self.device).manual_seed(seed) if seed >= 0 else None
            result = self.pipeline(
                image=model_in,
                condition_image=garment,
                mask=mask,
                num_inference_steps=steps,
                guidance_scale=guidance_scale,
                height=height,
                width=width,
                generator=generator,
            )[0]
            if color_fix:
                # Renk düzeltme: sonuçtaki kıyafet pikselleri (SCHP) kıyafet görselinin renklerine çekilir
                lip = np.array(self.automasker.process_schp_lip(result))
                cloth = np.isin(lip, CLOTH_LABELS[mask_type]) & (np.array(mask.convert("L")) > 127)
                result = match_colors(result, cloth, garment_raw)
            torch.cuda.synchronize()
            elapsed = time.perf_counter() - start
        # Tanı betiği (diag_tryon.py) ara adımları buradan okur
        self.last_debug = {"box": box, "model_in": model_in, "mask": mask, "raw": result}

        # Maske dışındaki alanları (yüz, arka plan) orijinal fotoğraftan geri al;
        # yüksek çözünürlükte yapılır ki yüz ve arka plan bulanıklaşmasın
        if region.size != (width, height):
            result = result.resize(region.size, Image.LANCZOS)
            mask = mask.convert("L").resize(region.size, Image.BILINEAR)
        blended = self._repaint(region, mask, result)
        if box:
            out = canvas.copy()
            out.paste(blended, box[:2])
        else:
            out = blended
        return TryOnOutput(
            image=out, person=canvas, mask=mask, category=mask_type, render_time_sec=round(elapsed, 2)
        )

    def check_photo(self, person: Image.Image, category: str) -> list[str]:
        """Deneme öncesi fotoğraf kontrolü (~0,3 sn): uyarı kodları, boş = sorun yok."""
        mask_type = self.normalize_category(category)
        person = ImageOps.exif_transpose(person).convert("RGB")
        small = resize_and_crop(person, (self.width, self.height))
        with self._lock:
            lip = self.automasker.process_schp_lip(small)
        return assess_photo(np.array(lip), person.size, mask_type)

    def face_ratio_of(self, person: Image.Image) -> float:
        """Kişi fotoğrafında yüz piksellerinin oranı (SCHP-LIP); arka kare tanıma için."""
        person = resize_and_crop(ImageOps.exif_transpose(person).convert("RGB"), (self.width, self.height))
        with self._lock:
            lip = self.automasker.process_schp_lip(person)
        return face_ratio(np.array(lip))

    def interpolate(self, a: Image.Image, b: Image.Image, n: int) -> list:
        """İki giydirilmiş kare arasında `n` ara kare (RIFE). GPU'yu kısa süre kullanır."""
        if self.rife is None:
            raise RuntimeError("RIFE yüklü değil")
        with self._lock:
            return self.rife.between(a, b, n)

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
