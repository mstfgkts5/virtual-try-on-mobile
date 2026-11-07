import inspect
import os

import main


def test_engine_defaults_fast_profile(monkeypatch):
    # Ölçüm (2026-11-07, şarjda): DPM-Solver++ 8 adım · 576x768 → 4,4 sn (DDIM 15 adım: 8,2 sn)
    src = inspect.getsource(main.lifespan)
    assert '"TRYON_WIDTH", "576"' in src and '"TRYON_HEIGHT", "768"' in src


def test_tryon_default_steps_8():
    sig = inspect.signature(main.process_tryon)
    assert sig.parameters["steps"].default.default == 8


def test_engine_run_default_steps_8():
    src = open(os.path.join(os.path.dirname(main.__file__), "engine.py"), encoding="utf-8").read()
    assert "steps: int = 8," in src
    assert "DPMSolverMultistepScheduler" in src and 'algorithm_type="dpmsolver++"' in src
