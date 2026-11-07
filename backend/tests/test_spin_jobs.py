import threading
import time

import pytest
from PIL import Image

from spin_jobs import SpinJobManager


class FakeClock:
    def __init__(self):
        self.t = 0.0

    def __call__(self):
        return self.t


def img(color):
    return Image.new("RGB", (4, 4), color)


class Recorder:
    """Sahte motor: her çağrıyı kaydeder, kişinin kopyasını sonuç olarak döner."""

    def __init__(self, fail_at=None):
        self.calls = []
        self.fail_at = fail_at

    def __call__(self, person, garment, category):
        self.calls.append((person, garment, category))
        if self.fail_at is not None and len(self.calls) - 1 == self.fail_at:
            raise RuntimeError("GPU hatası")
        return person.copy(), 1.5


FRONT, BACK = img("red"), img("blue")


def make(run=None, is_back=lambda p: False, clock=None):
    return SpinJobManager(run or Recorder(), is_back, clock=clock or FakeClock(), start_thread=False)


def frames(n):
    return [img((i * 10, 0, 0)) for i in range(n)]


def test_frames_processed_in_order():
    m = make()
    job = m.submit(frames(3), FRONT, None, "upper")
    for _ in range(3):
        assert m.step()
    s = m.status(job)
    assert s["status"] == "done"
    assert [f["index"] for f in s["frames"]] == [0, 1, 2]
    assert s["done"] == 3 and s["total"] == 3


def test_runner_called_per_frame():
    run = Recorder()
    m = make(run)
    m.submit(frames(4), FRONT, None, "upper")
    while m.step():
        pass
    assert len(run.calls) == 4


def test_since_returns_only_new_frames():
    m = make()
    job = m.submit(frames(3), FRONT, None, "upper")
    m.step()
    m.step()
    assert [f["index"] for f in m.status(job, since=1)["frames"]] == [1]


def test_back_frames_use_back_garment():
    run = Recorder()
    people = frames(3)
    m = make(run, is_back=lambda p: p is people[1])
    job = m.submit(people, FRONT, BACK, "upper")
    while m.step():
        pass
    assert run.calls[1][1] is BACK and run.calls[0][1] is FRONT
    assert m.status(job)["frames"][1]["view"] == "back"


def test_back_frames_fall_back_to_front():
    run = Recorder()
    m = make(run, is_back=lambda p: True)
    job = m.submit(frames(2), FRONT, None, "upper")
    while m.step():
        pass
    assert all(c[1] is FRONT for c in run.calls)
    assert all(f["view"] == "back" for f in m.status(job)["frames"])


def test_cancel_stops_after_current_frame():
    run = Recorder()
    m = make(run)
    job = m.submit(frames(3), FRONT, None, "upper")
    m.step()
    m.cancel(job)
    m.step()
    assert len(run.calls) == 1
    assert m.status(job)["status"] == "cancelled"


def test_heartbeat_timeout_cancels():
    run, clock = Recorder(), FakeClock()
    m = make(run, clock=clock)
    job = m.submit(frames(3), FRONT, None, "upper")
    clock.t = 31
    m.sweep()
    m.step()
    assert run.calls == []
    assert m.status(job)["status"] == "cancelled"


def test_status_keeps_job_alive():
    clock = FakeClock()
    m = make(clock=clock)
    job = m.submit(frames(3), FRONT, None, "upper")
    for t in (20, 40, 60):
        clock.t = t
        m.status(job)
        m.sweep()
    assert m.status(job)["status"] in ("queued", "running")


def test_max_job_time_fails():
    clock = FakeClock()
    m = make(clock=clock)
    job = m.submit(frames(3), FRONT, None, "upper")
    for t in range(0, 902, 20):
        clock.t = t
        m.status(job)
    m.sweep()
    s = m.status(job)
    assert s["status"] == "failed" and s["error"] == "Süre aşıldı"


def test_done_jobs_removed_after_keep():
    clock = FakeClock()
    m = make(clock=clock)
    job = m.submit(frames(1), FRONT, None, "upper")
    m.step()
    clock.t = 1801
    m.sweep()
    with pytest.raises(KeyError):
        m.status(job)


def test_fifo_two_jobs():
    run = Recorder()
    m = make(run)
    a = m.submit(frames(2), FRONT, None, "upper")
    b = m.submit(frames(2), FRONT, None, "lower")
    m.step()
    assert m.status(b)["status"] == "queued"
    m.step()
    assert m.status(a)["status"] == "done"
    m.step()
    assert run.calls[2][2] == "lower"


def test_runner_error_fails_job():
    run = Recorder(fail_at=0)
    m = make(run)
    a = m.submit(frames(2), FRONT, None, "upper")
    b = m.submit(frames(1), FRONT, None, "upper")
    m.step()
    s = m.status(a)
    assert s["status"] == "failed" and "GPU hatası" in s["error"]
    m.step()
    assert m.status(b)["status"] == "done"


def test_unknown_job_raises():
    m = make()
    with pytest.raises(KeyError):
        m.status("nope")
    with pytest.raises(KeyError):
        m.cancel("nope")


def test_single_tryon_can_run_between_frames():
    """Gerçek iş parçacığı + motorun kilidi: iş sürerken gelen tek kare denemesi işin bitmesini beklemez."""
    gpu = threading.Lock()  # CatVTONEngine._lock yerine
    order = []

    def run(person, garment, category):
        with gpu:
            order.append("spin")
            time.sleep(0.05)
        time.sleep(0.01)  # kareler arası iş (repaint, SCHP): kilit serbest
        return person.copy(), 0.05

    m = SpinJobManager(run, lambda p: False, start_thread=True)
    job = m.submit(frames(6), FRONT, None, "upper")
    while not order:  # ilk kare başlasın
        time.sleep(0.005)
    with gpu:  # tek kare denemesi (/api/v1/tryon) kilidi alır
        order.append("tryon")
    deadline = time.time() + 5
    while m.status(job)["status"] != "done" and time.time() < deadline:
        time.sleep(0.02)
    assert m.status(job)["status"] == "done"
    # Tek kare denemesi en fazla bir kare bekledi: son kareden önce araya girdi
    assert order.index("tryon") <= 2


# --- Ara kareler (akıcı dönüş) -----------------------------------------------

class FakeInterp:
    def __init__(self, fail=False):
        self.calls = []
        self.fail = fail

    def __call__(self, a, b, n):
        self.calls.append((a, b, n))
        if self.fail:
            raise RuntimeError("RIFE hatası")
        return [img((200, 200, 200)) for _ in range(n)]


def make_interp(interp, run=None):
    return SpinJobManager(run or Recorder(), lambda p: False, interpolate=interp, tweens=3,
                          clock=FakeClock(), start_thread=False)


def drain(m):
    while m.step():
        pass


def test_tweens_inserted_between_keys():
    interp = FakeInterp()
    m = make_interp(interp)
    job = m.submit(frames(3), FRONT, None, "upper")
    drain(m)
    s = m.status(job)
    assert s["status"] == "done" and s["total"] == 12
    assert [f["index"] for f in s["frames"]] == list(range(12))
    kinds = [f["kind"] for f in s["frames"]]
    assert kinds == ["key", "tween", "tween", "tween"] * 3
    # 0→1, 1→2 ve kapanış 2→0
    assert len(interp.calls) == 3 and all(c[2] == 3 for c in interp.calls)


def test_tweens_keep_indices_contiguous():
    m = make_interp(FakeInterp())
    job = m.submit(frames(4), FRONT, None, "upper")
    seen = []
    while m.step():
        got = m.status(job, since=len(seen))["frames"]
        seen += [f["index"] for f in got]
        assert seen == list(range(len(seen)))  # hiçbir an boşluk yok
    assert len(seen) == 16


def test_cancel_skips_closing_tweens():
    interp = FakeInterp()
    holder = {}

    def run(person, garment, category):
        # Son ana kare işlenirken iş iptal edilir: o kare kaydedilir ama tur kapatılmaz
        if len(run.calls) == 1:
            holder["m"].cancel(holder["job"])
        run.calls.append(person)
        return person.copy(), 1.0

    run.calls = []
    m = make_interp(interp, run=run)
    holder["m"] = m
    holder["job"] = m.submit(frames(2), FRONT, None, "upper")
    m.step()
    m.step()
    s = m.status(holder["job"])
    assert s["status"] == "cancelled"
    assert len(interp.calls) == 1  # yalnızca 0→1, kapanış (1→0) yok
    assert len(s["frames"]) == 5


def test_interpolate_error_falls_back_to_blend():
    m = make_interp(FakeInterp(fail=True))
    job = m.submit(frames(2), FRONT, None, "upper")
    drain(m)
    s = m.status(job)
    assert s["status"] == "done" and len(s["frames"]) == 8
    assert [f["kind"] for f in s["frames"]].count("tween") == 6


def test_single_key_no_tweens():
    interp = FakeInterp()
    m = make_interp(interp)
    job = m.submit(frames(1), FRONT, None, "upper")
    drain(m)
    s = m.status(job)
    assert s["total"] == 1 and len(s["frames"]) == 1 and interp.calls == []


def test_without_interpolator_kind_is_key():
    m = make()
    job = m.submit(frames(2), FRONT, None, "upper")
    drain(m)
    assert [f["kind"] for f in m.status(job)["frames"]] == ["key", "key"]
