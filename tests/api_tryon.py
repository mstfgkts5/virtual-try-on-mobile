"""Çalışan backend'e (localhost:8000) gerçek API isteği atar; uygulamanın yaptığı çağrının aynısı.

Kullanım (proje kökünden, backend açıkken):
  backend\\venv\\Scripts\\python tests\\api_tryon.py <kişi.jpg> <kıyafet.png> <upper|lower|overall> <çıktı.png>
Sonuç görselinin yanına kırpılmış kişi fotoğrafını (<çıktı>_person.jpg) da kaydeder.
"""
import base64
import sys
import time

import requests

sys.stdout.reconfigure(encoding="utf-8")


def main():
    person, garment, category, out = sys.argv[1:5]
    start = time.perf_counter()
    with open(person, "rb") as p, open(garment, "rb") as g:
        resp = requests.post(
            "http://127.0.0.1:8000/api/v1/tryon",
            files={"person_image": p, "garment_image": g},
            data={"category": category},
            timeout=300,
        )
    total = time.perf_counter() - start
    if resp.status_code != 200:
        print(f"HATA {resp.status_code}: {resp.text}")
        sys.exit(1)
    data = resp.json()
    with open(out, "wb") as f:
        f.write(base64.b64decode(data["image_base64"]))
    with open(out.replace(".png", "_person.jpg"), "wb") as f:
        f.write(base64.b64decode(data["person_base64"]))
    print(f"{category}: model {data['render_time']} sn, toplam {total:.1f} sn -> {out}")


if __name__ == "__main__":
    main()
