"""Testler için bellekte sentetik video üretir (PyAV)."""
import io

import av
import numpy as np


def make_video(w: int, h: int, seconds: float, fps: int = 30, rotate: int = 0, marker: bool = False) -> bytes:
    """Her karenin parlaklığı kare numarasıyla artar; marker=True ise sol yarı kırmızı olur."""
    buf = io.BytesIO()
    c = av.open(buf, "w", format="mp4")
    s = c.add_stream("libx264", rate=fps)
    s.width, s.height, s.pix_fmt = w, h, "yuv420p"
    if rotate:
        s.set_display_rotation(rotate)
    n = max(1, int(seconds * fps))
    for i in range(n):
        level = int(255 * i / max(1, n - 1))
        arr = np.full((h, w, 3), level, np.uint8)
        if marker:
            arr[:, : w // 2] = (255, 0, 0)
        for p in s.encode(av.VideoFrame.from_ndarray(arr, format="rgb24")):
            c.mux(p)
    for p in s.encode():
        c.mux(p)
    c.close()
    return buf.getvalue()
