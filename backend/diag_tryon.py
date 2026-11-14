"""Gerçek fotoğraf tanısı: aynı kişi + kıyafet farklı ayarlarla, ara adımlar yan yana.
Kullanım: python diag_tryon.py <kisi.jpg>   ->  ../report_figures/diag_<kiyafet>.jpg
"""
import os
import sys

from PIL import Image, ImageDraw

from diffusers import DDIMScheduler, DPMSolverMultistepScheduler

from engine import CatVTONEngine

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GARMENTS = ["shirt-stripe", "blazer", "sweater-wave"]
CONFIGS = [  # (etiket, ayar sözlüğü)
    ("G simdiki: DPM++ 8 adim", {}),
    ("G + renk duzeltme", {"color_fix": True}),
    ("L DPM++ 8 trailing", {"sched": "trailing"}),
    ("K orijinal CatVTON: DDIM 50 adim", {"sched": "ddim", "steps": 50}),
]
H = 640


def fit(img):
    return img.resize((round(img.width * H / img.height), H))


def label(img, text):
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, img.width, 22), fill="black")
    d.text((4, 4), text, fill="white")
    return img


def main(person_path):
    eng = CatVTONEngine(768, 1024)
    dpm = eng.pipeline.noise_scheduler
    base_cfg = dpm.config
    person = Image.open(person_path)
    out_dir = os.path.join(ROOT, "report_figures")
    os.makedirs(out_dir, exist_ok=True)
    lines = []
    for g in GARMENTS:
        garment = Image.open(os.path.join(ROOT, "see_it_on", "assets", "images", "garments", g + ".jpg"))
        tiles = [label(fit(garment.convert("RGB")), f"kiyafet {g} {garment.size}")]
        for i, (name, cfg) in enumerate(CONFIGS):
            sched = cfg.get("sched")
            if sched == "ddim":
                eng.pipeline.noise_scheduler = DDIMScheduler.from_config(base_cfg)
            elif sched == "trailing":
                eng.pipeline.noise_scheduler = DPMSolverMultistepScheduler.from_config(
                    base_cfg, algorithm_type="dpmsolver++", solver_order=2, timestep_spacing="trailing")
            else:
                eng.pipeline.noise_scheduler = dpm
            o = eng.run(person, garment, "upper", steps=cfg.get("steps", 8), color_fix=cfg.get("color_fix", False))
            crop = False
            o.image.convert("RGB").save(os.path.join(out_dir, f"full_{g}_{i}.jpg"), quality=92)
            dbg = eng.last_debug
            if crop:
                ov = dbg["model_in"].convert("RGB").copy()
                red = Image.new("RGB", ov.size, (255, 0, 0))
                ov = Image.composite(Image.blend(ov, red, 0.45), ov, dbg["mask"].convert("L").resize(ov.size))
                tiles.append(label(fit(ov), f"maske ({name})"))
            tiles.append(label(fit(o.image), f"{name} son {o.render_time_sec}s"))
            lines.append(f"{g}\t{name}\t{o.render_time_sec}s\tbox={dbg['box']}\tcanvas={o.person.size}")
        sheet = Image.new("RGB", (sum(t.width for t in tiles), H), "white")
        x = 0
        for t in tiles:
            sheet.paste(t, (x, 0))
            x += t.width
        sheet.save(os.path.join(out_dir, f"diag_{g}.jpg"), quality=88)
    with open(os.path.join(out_dir, "diag_times.txt"), "w", encoding="utf-8") as f:
        f.write(f"person {person.size}\n" + "\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main(sys.argv[1])
