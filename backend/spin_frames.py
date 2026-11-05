"""360° dönüş için videodan kare çıkarma ve arka kare tanıma yardımcıları (GPU gerektirmez)."""
import io

import av
import numpy as np
from PIL import Image, ImageOps

MAX_VIDEO_BYTES = 60 * 1024 * 1024
MAX_DURATION_S = 30.0
VIDEO_HINT = "Video açılamadı. MP4/H.264 olarak kaydedin (iPhone: Ayarlar → Kamera → Formatlar → En Uyumlu)."


class VideoError(ValueError):
    """Video okunamadı veya kurallara uymuyor; mesaj kullanıcıya gösterilir."""


def sample_times(duration: float, n: int, trim: float = 0.05) -> list[float]:
    """Baştan ve sondan `trim` oranı atlanır; kalan süreden eşit aralıklı `n` zaman (sn)."""
    start, end = duration * trim, duration * (1 - trim)
    step = (end - start) / n
    return [start + i * step for i in range(n)]


def _duration(container, stream) -> float | None:
    if stream.duration is not None and stream.time_base is not None:
        return float(stream.duration * stream.time_base)
    if container.duration is not None:
        return container.duration / av.time_base
    return None


def _to_portrait_image(frame: "av.VideoFrame", size: tuple[int, int]) -> Image.Image:
    img = frame.to_image()
    rotation = int(getattr(frame, "rotation", 0) or 0)
    if rotation:
        # Telefonun döndürme bilgisi (saat yönünün tersine derece): görüntü dik hâline getirilir
        img = img.rotate(rotation, expand=True)
    return ImageOps.fit(img.convert("RGB"), size, method=Image.LANCZOS, centering=(0.5, 0.5))


def extract_frames(data: bytes, n: int, size: tuple[int, int] = (768, 1024)) -> list[Image.Image]:
    """Videodan eşit aralıklı `n` dikey kare (3:4, `size`) çıkarır. Video bellekten okunur, diske yazılmaz."""
    try:
        container = av.open(io.BytesIO(data))
    except Exception as e:  # PyAV/ffmpeg tüm açılamama hataları
        raise VideoError(VIDEO_HINT) from e
    try:
        if not container.streams.video:
            raise VideoError(VIDEO_HINT)
        stream = container.streams.video[0]
        duration = _duration(container, stream)
        if duration is None or duration <= 0:
            raise VideoError(VIDEO_HINT)
        if duration > MAX_DURATION_S:
            raise VideoError(f"Video en fazla {int(MAX_DURATION_S)} saniye olabilir.")

        targets = sample_times(duration, n)
        frames: list[Image.Image] = []
        last: "av.VideoFrame | None" = None
        try:
            for frame in container.decode(stream):
                t = frame.time if frame.time is not None else 0.0
                while len(frames) < n and t >= targets[len(frames)]:
                    frames.append(_to_portrait_image(frame, size))
                last = frame
                if len(frames) == n:
                    break
        except av.FFmpegError as e:
            raise VideoError(VIDEO_HINT) from e

        # Son hedefler son karenin zamanından ileri düşebilir (kısa/eksik videolar): son kareyle tamamla
        if frames and len(frames) < n and last is not None and len(frames) >= n - 1:
            frames.append(_to_portrait_image(last, size))
        if len(frames) < n or _too_similar(frames):
            raise VideoError("Videodan yeterli kare alınamadı; 10–20 saniyelik bir dönüş videosu deneyin.")
        return frames
    finally:
        container.close()


def _too_similar(frames: list[Image.Image]) -> bool:
    """Çok kısa videoda aynı kare defalarca alınır; bu durumda dönüş anlamsızdır."""
    small = [np.asarray(f.resize((16, 16))).astype(int) for f in frames]
    distinct = {s.tobytes() for s in small}
    return len(distinct) < max(2, len(frames) // 2)


# SCHP-LIP etiketlerinde yüz; ai/CatVTON/model/cloth_masker.py LIP_MAPPING ile aynı
LIP_FACE = 13
# Yüz pikseli / kişi pikseli bu oranın altındaysa kişi arkası dönük sayılır.
# Ölçüm (2026-11-05): tam arka 0.000; ön, 3/4 ön ve profil 0.040–0.052 (mankenler + gerçek foto).
# 0.015, yüzün küçük bir kısmı görünen 3/4 arka kareleri de arka sayar.
BACK_FACE_RATIO = 0.015


def face_ratio(lip: np.ndarray) -> float:
    """SCHP-LIP etiket haritasında yüz piksellerinin kişi piksellerine oranı; kişi yoksa 0."""
    lip = np.asarray(lip)
    person = np.count_nonzero(lip)
    if person == 0:
        return 0.0
    return float(np.count_nonzero(lip == LIP_FACE)) / person
