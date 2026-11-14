import inspect
import os

import main


def test_engine_defaults_fast_profile(monkeypatch):
    # Tam sonuç CatVTON'un eğitim çözünürlüğünde (768x1024); 360° kareleri hızlı profilde (576x768)
    src = inspect.getsource(main.lifespan)
    assert '"TRYON_WIDTH", "768"' in src and '"TRYON_HEIGHT", "1024"' in src
    assert main.SPIN_SIZE == (576, 768) and "size=SPIN_SIZE" in src


def test_tryon_default_steps_8():
    sig = inspect.signature(main.process_tryon)
    assert sig.parameters["steps"].default.default == 8


def test_engine_run_default_steps_8():
    src = open(os.path.join(os.path.dirname(main.__file__), "engine.py"), encoding="utf-8").read()
    assert "steps: int = 8," in src
    assert "DPMSolverMultistepScheduler" in src and 'algorithm_type="dpmsolver++"' in src


def test_full_result_uses_color_fix_by_default():
    # Tanı (2026-11-14): renk düzeltme soluk kıyafet renklerini geri getirdi; önizleme ve 360° hızlı kalır
    src = open(os.path.join(os.path.dirname(main.__file__), "engine.py"), encoding="utf-8").read()
    assert "color_fix: bool | None = None," in src and "color_fix = size is None" in src
