"""360° dönüşte ana kareler arasına RIFE ile ara kare üretimi."""
import os

import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image

RIFE_MODEL = "TensorForger/RIFE-safetensors"  # MIT; yalnızca ağırlık dosyası indirilir
RIFE_WEIGHTS = "flownet.safetensors"


def recursive_midpoints(a, b, n: int, mid) -> list:
    """`a` ile `b` arasında eşit aralıklı `n` ara değer; `mid(x, y)` tam ortayı verir.
    RIFE yalnızca orta kareyi ürettiği için n = 2^k − 1 (1, 3, 7) olmalıdır."""
    if n == 0:
        return []
    if n < 0 or (n + 1) & n:
        raise ValueError("Ara kare sayısı 1, 3 veya 7 olmalı.")
    m = mid(a, b)
    half = (n - 1) // 2
    return recursive_midpoints(a, m, half, mid) + [m] + recursive_midpoints(m, b, half, mid)


def pad_to_multiple(t: torch.Tensor, k: int = 32) -> tuple[torch.Tensor, tuple[int, int]]:
    """Yükseklik/genişliği `k`'nın katına kenar tekrarıyla genişletir; asıl boyut da döner."""
    h, w = t.shape[-2:]
    ph, pw = (k - h % k) % k, (k - w % k) % k
    if ph or pw:
        t = F.pad(t, (0, pw, 0, ph), mode="replicate")
    return t, (h, w)


class RifeInterpolator:
    def __init__(self, weights_path: str, device: str = "cuda"):
        from safetensors.torch import load_file

        from rife_ifnet import IFNet

        self.device = device
        self.dtype = torch.float16 if device == "cuda" else torch.float32
        net = IFNet()
        net.load_state_dict(load_file(weights_path))
        self.net = net.to(device, self.dtype).eval()

    @classmethod
    def from_hub(cls, device: str = "cuda") -> "RifeInterpolator":
        from huggingface_hub import snapshot_download

        path = snapshot_download(RIFE_MODEL, allow_patterns=[RIFE_WEIGHTS, "LICENSE"])
        return cls(os.path.join(path, RIFE_WEIGHTS), device)

    def _to_tensor(self, img: Image.Image) -> torch.Tensor:
        arr = np.array(img.convert("RGB"), dtype=np.float32) / 255.0
        return torch.from_numpy(arr).permute(2, 0, 1).unsqueeze(0).to(self.device, self.dtype)

    @staticmethod
    def _to_image(t: torch.Tensor) -> Image.Image:
        arr = (t[0].clamp(0, 1).permute(1, 2, 0).float().cpu().numpy() * 255).round().astype(np.uint8)
        return Image.fromarray(arr)

    @torch.no_grad()
    def between(self, a: Image.Image, b: Image.Image, n: int) -> list[Image.Image]:
        """`a` ve `b` (aynı boyut) arasında `n` ara kare, sırayla."""
        if a.size != b.size:
            b = b.resize(a.size, Image.LANCZOS)
        ta, (h, w) = pad_to_multiple(self._to_tensor(a))
        tb, _ = pad_to_multiple(self._to_tensor(b))
        mids = recursive_midpoints(ta, tb, n, lambda x, y: self.net(torch.cat([x, y], 1)))
        return [self._to_image(m[..., :h, :w]) for m in mids]
