"""360° dönüş işleri: bellekte FIFO kuyruk, kare kare işleme, kalp atışı ve süre sınırı.

Motor (CatVTON) dışarıdan fonksiyon olarak verilir; böylece kuyruk GPU olmadan test edilir.
Her kare `run` ile ayrı çağrılır: motorun kilidi kareler arasında bırakılır, araya gelen
tek kare denemesi (`/api/v1/tryon`) en fazla bir kare bekler.

Akıcı dönüş için `interpolate` verilirse her yeni ana karenin önüne, önceki ana kareyle arasındaki
`tweens` adet ara kare eklenir; son ana kareden sonra son→ilk arası eklenerek tur kapanır.
Kareler genişletilmiş sırayla numaralanır (ana kare k → k * (tweens + 1)) ve hep bitişik gelir.
"""
import threading
import time
import uuid
from dataclasses import dataclass, field
from typing import Callable, Optional

from PIL import Image

Runner = Callable[[Image.Image, Image.Image, str], tuple[Image.Image, float]]
BackCheck = Callable[[Image.Image], bool]
Interpolator = Callable[[Image.Image, Image.Image, int], list]

ACTIVE = ("queued", "running")


@dataclass
class _Job:
    id: str
    frames: list
    front: Image.Image
    back: Optional[Image.Image]
    category: str
    created: float
    last_seen: float
    status: str = "queued"
    results: list = field(default_factory=list)
    keys: list = field(default_factory=list)  # giydirilmiş ana kareler (sırayla)
    error: Optional[str] = None
    finished: Optional[float] = None


class SpinJobManager:
    def __init__(
        self,
        run: Runner,
        is_back: BackCheck,
        heartbeat_s: float = 30.0,
        max_job_s: float = 900.0,
        keep_done_s: float = 1800.0,
        clock: Callable[[], float] = time.monotonic,
        start_thread: bool = True,
        interpolate: Optional[Interpolator] = None,
        tweens: int = 3,
    ):
        self._run, self._is_back = run, is_back
        self._interpolate = interpolate
        self._tweens = tweens if interpolate is not None else 0
        self._heartbeat, self._max_job, self._keep = heartbeat_s, max_job_s, keep_done_s
        self._clock = clock
        self._jobs: dict[str, _Job] = {}  # ekleme sırası = FIFO
        self._lock = threading.Lock()
        if start_thread:
            threading.Thread(target=self._loop, name="spin-worker", daemon=True).start()

    # --- Dışa açık işlemler -------------------------------------------------
    def submit(self, frames: list, garment_front: Image.Image, garment_back: Optional[Image.Image], category: str) -> str:
        now = self._clock()
        job = _Job(uuid.uuid4().hex, list(frames), garment_front, garment_back, category, now, now)
        with self._lock:
            self._jobs[job.id] = job
        return job.id

    def status(self, job_id: str, since: int = 0) -> dict:
        with self._lock:
            job = self._jobs[job_id]
            job.last_seen = self._clock()  # kalp atışı
            return {
                "status": job.status,
                "total": self._total(job),
                "done": len(job.results),
                "frames": [r for r in job.results if r["index"] >= since],
                "error": job.error,
            }

    def cancel(self, job_id: str) -> None:
        with self._lock:
            self._finish(self._jobs[job_id], "cancelled")

    def step(self) -> bool:
        """Sıradaki işin bir karesini işler; iş yoksa False."""
        self.sweep()
        with self._lock:
            job = next((j for j in self._jobs.values() if j.status in ACTIVE), None)
            if job is None:
                return False
            job.status = "running"
            k = len(job.keys)
            person = job.frames[k]
        try:
            back = self._is_back(person)
            garment = job.back if (back and job.back is not None) else job.front
            image, seconds = self._run(person, garment, job.category)
        except Exception as e:  # motor hatası işi bitirir, kuyruk devam eder
            with self._lock:
                job.error = str(e)
                self._finish(job, "failed")
            return True
        view = "back" if back else "front"
        between = self._tweens_between(job.keys[-1]["image"], image) if k > 0 and self._tweens else []
        last = k == len(job.frames) - 1
        with self._lock:
            # Kare işlenirken iş iptal edildiyse bu kare yine kaydedilir; sonraki kareler yapılmaz
            self._append_tweens(job, between, job.keys[-1]["view"] if job.keys else view)
            key = {"index": k * (self._tweens + 1), "kind": "key", "view": view, "image": image, "render_time": seconds}
            job.keys.append(key)
            job.results.append(key)
            closing = last and job.status == "running" and self._tweens and len(job.frames) > 1
            first = job.keys[0]["image"]
        if closing:
            # Turu kapatan son→ilk ara kareleri
            closing_tweens = self._tweens_between(image, first)
            with self._lock:
                if job.status == "running":
                    self._append_tweens(job, closing_tweens, view)
        with self._lock:
            if job.status == "running" and len(job.keys) == len(job.frames):
                self._finish(job, "done")
        return True

    def sweep(self) -> None:
        """Sahipsiz işleri iptal eder, süreyi aşanları bitirir, eski işleri siler."""
        now = self._clock()
        with self._lock:
            for job_id, job in list(self._jobs.items()):
                if job.status in ACTIVE:
                    if now - job.last_seen >= self._heartbeat:
                        self._finish(job, "cancelled")
                    elif now - job.created >= self._max_job:
                        job.error = "Süre aşıldı"
                        self._finish(job, "failed")
                elif job.finished is not None and now - job.finished >= self._keep:
                    del self._jobs[job_id]

    # --- İç işler -----------------------------------------------------------
    def _total(self, job: _Job) -> int:
        n = len(job.frames)
        return n * (self._tweens + 1) if self._tweens and n > 1 else n

    def _tweens_between(self, a: Image.Image, b: Image.Image) -> list:
        try:
            out = list(self._interpolate(a, b, self._tweens))
            if len(out) == self._tweens:
                return out
        except Exception as e:  # ara kare hatası işi durdurmaz
            print(f"[SeeItOn] Ara kare üretilemedi, karışımla devam: {e}")
        # Yedek: iki ana karenin doğrusal karışımı (indeksler bitişik kalsın)
        n = self._tweens
        return [Image.blend(a, b, (i + 1) / (n + 1)) for i in range(n)]

    def _append_tweens(self, job: _Job, tweens: list, view: str) -> None:
        start = len(job.results)
        for i, t in enumerate(tweens):
            job.results.append({"index": start + i, "kind": "tween", "view": view, "image": t, "render_time": 0.0})

    def _finish(self, job: _Job, status: str) -> None:
        if job.status in ACTIVE:
            job.status = status
            job.finished = self._clock()

    def _loop(self) -> None:
        while True:
            try:
                worked = self.step()
            except Exception as e:  # iş parçacığı hiçbir koşulda ölmemeli
                print(f"[SeeItOn] Spin işçisi hatası: {e}")
                worked = False
            if not worked:
                time.sleep(0.2)
