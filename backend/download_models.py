"""CatVTON için gereken model ağırlıklarını Hugging Face önbelleğine indirir.

Dosyalar OneDrive klasörüne değil, kullanıcının HF önbelleğine (~/.cache/huggingface) iner.
Kullanım:  venv\\Scripts\\python download_models.py
"""
import sys

from huggingface_hub import snapshot_download

sys.stdout.reconfigure(encoding="utf-8")  # Windows konsolunda Türkçe karakterler için

BASE_MODEL = "booksforcharlie/stable-diffusion-inpainting"
VAE_MODEL = "stabilityai/sd-vae-ft-mse"
CATVTON_MODEL = "zhengchong/CatVTON"
RIFE_MODEL = "TensorForger/RIFE-safetensors"  # 360° dönüş ara kareleri (MIT)


def main():
    print(f"[1/4] {BASE_MODEL} (unet + scheduler)")
    snapshot_download(
        BASE_MODEL,
        allow_patterns=["scheduler/*", "unet/config.json", "unet/diffusion_pytorch_model.bin"],
    )
    print(f"[2/4] {VAE_MODEL}")
    snapshot_download(VAE_MODEL, allow_patterns=["config.json", "diffusion_pytorch_model.safetensors"])
    print(f"[3/4] {CATVTON_MODEL} (attention + DensePose + SCHP)")
    snapshot_download(CATVTON_MODEL)
    print(f"[4/4] {RIFE_MODEL} (yalnızca ağırlık)")
    snapshot_download(RIFE_MODEL, allow_patterns=["flownet.safetensors", "LICENSE"])
    print("Tüm modeller hazır.")


if __name__ == "__main__":
    main()
