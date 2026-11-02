"""SeeItOn test mankenlerini yerel GPU'da (RealVisXL V5, SDXL) üretir.

Gerçek kişi fotoğrafı kullanılmadığı için gizlilik/telif sorunu yoktur.
Her manken için birkaç aday üretilir, en iyisi elle seçilir.

Kullanım (proje kökünden):
  backend\\venv\\Scripts\\python tools\\generate_mannequins.py                 # 8 mankenin hepsi, önden, 4'er aday
  backend\\venv\\Scripts\\python tools\\generate_mannequins.py --only W-M M-L   # sadece seçilenler
  backend\\venv\\Scripts\\python tools\\generate_mannequins.py --view back --seed 1234 --only W-M
Çıktı: test_images/mannequins/<id>/<görünüm>_<seed>.png ve test_images/mannequins/mannequins.json
"""
import argparse
import json
import os
import sys

sys.stdout.reconfigure(encoding="utf-8")
os.environ.setdefault("HF_HUB_DISABLE_XET", "1")

import torch  # noqa: E402
from diffusers import AutoencoderKL, DPMSolverMultistepScheduler, StableDiffusionXLPipeline  # noqa: E402
from huggingface_hub import snapshot_download  # noqa: E402

MODEL = "SG161222/RealVisXL_V5.0"
VAE = "madebyollin/sdxl-vae-fp16-fix"
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "test_images", "mannequins")
WIDTH, HEIGHT = 896, 1152  # ~3:4, CatVTON'un 768x1024 oranına uygun

# Kilo değerleri boya göre beden tablosundan seçildi; model kiloyu anlamadığı için
# her bedenin vücut tarifi ayrıca yazıldı.
# SDXL metin kodlayıcısı yalnızca ilk 77 token'ı okur; en önemli bilgiler (tam boy, kişi,
# beden) başa yazılır ve tarif kısa tutulur.
WOMAN = "30yo Turkish woman, long straight black hair, fair skin"
MAN = "30yo Turkish man, short black hair, fair skin"
MANNEQUINS = [
    {"id": "W-S", "gender": "female", "size": "S", "height_cm": 160, "weight_kg": 50, "body": "slim slender body"},
    {"id": "W-M", "gender": "female", "size": "M", "height_cm": 160, "weight_kg": 58, "body": "average healthy body"},
    {"id": "W-L", "gender": "female", "size": "L", "height_cm": 160, "weight_kg": 67, "body": "chubby full-figured body"},
    {"id": "W-XL", "gender": "female", "size": "XL", "height_cm": 160, "weight_kg": 76, "body": "plus-size heavy body"},
    {"id": "M-S", "gender": "male", "size": "S", "height_cm": 185, "weight_kg": 72, "body": "slim lean body"},
    {"id": "M-M", "gender": "male", "size": "M", "height_cm": 185, "weight_kg": 80, "body": "average athletic body"},
    {"id": "M-L", "gender": "male", "size": "L", "height_cm": 185, "weight_kg": 90, "body": "stocky body, slight belly"},
    {"id": "M-XL", "gender": "male", "size": "XL", "height_cm": 185, "weight_kg": 100, "body": "plus-size body, big belly"},
]

VIEWS = {
    "front": "front view facing camera",
    "side": "side profile view",
    "back": "back view from behind",
}

# Kot pantolon modelde "eller cepte" pozunu çağırıyor; cepsiz pantolon ve duruşun başta yazılması bunu engelliyor
POSE = "A-pose, arms straight and slightly away from hips, open hands visible"
# CatVTON için sade, dar kıyafet ve düz arka plan en iyi sonucu verir
OUTFIT = "plain white t-shirt, grey leggings, white sneakers"
STYLE = "plain light grey studio background, e-commerce catalog photo, photorealistic"
NEGATIVE = ("nsfw, hands in pockets, hands on hips, crossed arms, cropped, cut off feet, cut off head, close-up, holding object, "
            "jacket, logo, text, watermark, busy background, deformed hands, extra fingers, extra limbs, "
            "distorted body, blurry, lowres, cartoon, 3d render")


def build_prompt(m: dict, view: str) -> str:
    person = WOMAN if m["gender"] == "female" else MAN
    return f"full body photo head to toe, {POSE}, {VIEWS[view]}, {person}, {m['body']}, {OUTFIT}, {STYLE}"


def download_models() -> str:
    snapshot_download(VAE, allow_patterns=["config.json", "diffusion_pytorch_model.safetensors"])
    return snapshot_download(MODEL, allow_patterns=[
        "model_index.json", "scheduler/*", "tokenizer/*", "tokenizer_2/*",
        "text_encoder/config.json", "text_encoder/model.fp16.safetensors",
        "text_encoder_2/config.json", "text_encoder_2/model.fp16.safetensors",
        "unet/config.json", "unet/diffusion_pytorch_model.fp16.safetensors", "vae/config.json",
    ])


def load_pipeline() -> StableDiffusionXLPipeline:
    path = download_models()
    vae = AutoencoderKL.from_pretrained(VAE, torch_dtype=torch.float16)
    pipe = StableDiffusionXLPipeline.from_pretrained(path, vae=vae, torch_dtype=torch.float16, variant="fp16")
    pipe.scheduler = DPMSolverMultistepScheduler.from_config(
        pipe.scheduler.config, use_karras_sigmas=True, algorithm_type="dpmsolver++"
    )
    pipe.enable_model_cpu_offload()  # 8 GB VRAM'e sığması için modelleri sırayla GPU'ya alır
    pipe.enable_vae_tiling()
    return pipe


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", nargs="*", help="Üretilecek manken id'leri (örn. W-M M-L)")
    parser.add_argument("--view", default="front", choices=VIEWS.keys())
    parser.add_argument("--candidates", type=int, default=4)
    parser.add_argument("--seed", type=int, help="Tek bir seed ile üret (farklı açıda aynı kişi için)")
    parser.add_argument("--steps", type=int, default=30)
    parser.add_argument("--download-only", action="store_true", help="Sadece model ağırlıklarını indir")
    args = parser.parse_args()

    if args.download_only:
        download_models()
        print("RealVisXL modeli hazır.")
        return

    selected = [m for m in MANNEQUINS if not args.only or m["id"] in args.only]
    os.makedirs(OUT_DIR, exist_ok=True)
    with open(os.path.join(OUT_DIR, "mannequins.json"), "w", encoding="utf-8") as f:
        json.dump(MANNEQUINS, f, ensure_ascii=False, indent=2)

    pipe = load_pipeline()
    for m in selected:
        folder = os.path.join(OUT_DIR, m["id"])
        os.makedirs(folder, exist_ok=True)
        prompt = build_prompt(m, args.view)
        seeds = [args.seed] if args.seed is not None else [1000 + i for i in range(args.candidates)]
        for seed in seeds:
            image = pipe(
                prompt=prompt,
                negative_prompt=NEGATIVE,
                width=WIDTH,
                height=HEIGHT,
                num_inference_steps=args.steps,
                guidance_scale=4.5,
                generator=torch.Generator("cpu").manual_seed(seed),
            ).images[0]
            out = os.path.join(folder, f"{args.view}_{seed}.png")
            image.save(out)
            print(f"[{m['id']}] {m['size']} {m['height_cm']}cm/{m['weight_kg']}kg -> {out}")


if __name__ == "__main__":
    main()
