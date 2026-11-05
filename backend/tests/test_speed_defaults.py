import inspect
import os

import main


def test_engine_defaults_fast_profile(monkeypatch):
    # Ölçüm (2026-11-05): 15 adım · 576x768 · rehberlik 2.5 → 16.8 sn (30 adım · 768x1024: 73.6 sn)
    src = inspect.getsource(main.lifespan)
    assert '"TRYON_WIDTH", "576"' in src and '"TRYON_HEIGHT", "768"' in src


def test_tryon_default_steps_15():
    sig = inspect.signature(main.process_tryon)
    assert sig.parameters["steps"].default.default == 15


def test_engine_run_default_steps_15():
    src = open(os.path.join(os.path.dirname(main.__file__), "engine.py"), encoding="utf-8").read()
    assert "steps: int = 15," in src
