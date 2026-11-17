"""Gizlilik: telefon fotoğraflarındaki EXIF (GPS konumu dahil) uygulamanın döndürdüğü görsellere taşınmaz."""
import base64
import io

from PIL import Image, ImageOps

import main


def photo_with_gps() -> Image.Image:
    exif = Image.Exif()
    exif[0x0112] = 6  # yönlendirme (telefonlar yazar)
    exif[0x8825] = {1: "N", 2: (41.0, 0.0, 0.0), 3: "E", 4: (29.0, 0.0, 0.0)}  # GPS
    buf = io.BytesIO()
    Image.new("RGB", (64, 48), "red").save(buf, "JPEG", exif=exif.tobytes())
    return Image.open(io.BytesIO(buf.getvalue()))


def test_input_really_has_gps():
    assert photo_with_gps().getexif().get_ifd(0x8825)


def test_returned_images_carry_no_exif_or_gps():
    # engine.run'daki gibi: EXIF dönüşü, kırpma ve boyutlandırma; ardından API'nin kodlaması
    img = ImageOps.exif_transpose(photo_with_gps()).convert("RGB").crop((0, 0, 40, 40)).resize((30, 40))
    for fmt in ("JPEG", "PNG"):
        out = Image.open(io.BytesIO(base64.b64decode(main._encode(img, fmt))))
        assert not out.getexif().get_ifd(0x8825), fmt
        assert len(out.getexif()) == 0, fmt
