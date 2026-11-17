"""Ölçüm betikleri için küçük HTTP yardımcısı (yalnızca standart kütüphane)."""
import json
import mimetypes
import time
import urllib.error
import urllib.request
import uuid


def post_tryon(base_url, person_bytes, garment_bytes, category, steps=None, preview=False, timeout=300):
    """POST /api/v1/tryon; (http_kodu, json_yanıt, toplam_süre_sn) döner."""
    boundary = uuid.uuid4().hex
    parts = []

    def field(name, value):
        parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode())

    def file(name, filename, data):
        ctype = mimetypes.guess_type(filename)[0] or "application/octet-stream"
        parts.append(
            f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"; filename="{filename}"\r\n'
            f"Content-Type: {ctype}\r\n\r\n".encode() + data + b"\r\n"
        )

    file("person_image", "person.jpg", person_bytes)
    file("garment_image", "garment.jpg", garment_bytes)
    field("category", category)
    if steps is not None:
        field("steps", str(steps))
    if preview:
        field("preview", "true")
    body = b"".join(parts) + f"--{boundary}--\r\n".encode()
    req = urllib.request.Request(
        f"{base_url}/api/v1/tryon", data=body, method="POST",
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
    )
    t0 = time.perf_counter()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            data = json.loads(r.read())
            return r.status, data, time.perf_counter() - t0
    except urllib.error.HTTPError as e:
        return e.code, {"detail": e.read().decode("utf-8", "replace")}, time.perf_counter() - t0
    except Exception as e:  # bağlantı/zaman aşımı
        return 0, {"detail": repr(e)}, time.perf_counter() - t0


def get_json(url, timeout=10):
    with urllib.request.urlopen(url, timeout=timeout) as r:
        return json.loads(r.read())
