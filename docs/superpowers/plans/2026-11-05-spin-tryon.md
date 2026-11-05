# 360° Dönüş Denemesi (Spin Try-On) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bir dönüş videosundan (veya hazır setten) 8 giydirilmiş kare üretip parmakla döndürülen bir görüntüleyicide göstermek.

**Architecture:** Backend videoyu PyAV ile karelere böler, her kareyi mevcut `CatVTONEngine` ile sırayla giydirir; işler bellekteki bir kuyrukta, iş numarasıyla izlenir (POST/GET/DELETE). Flutter tarafı işi başlatır, 3 sn'de bir durumu sorar, gelen kareleri `SpinViewer`'da gösterir; hazır set aynı görüntüleyiciyi paketlenmiş karelerle açar.

**Tech Stack:** FastAPI, PyAV 18 (`av`, zaten requirements'ta), CatVTON, pytest (yeni, yalnızca geliştirme), Flutter 3 + gen-l10n, `image_picker.pickVideo`, `http`.

**Spec:** `docs/superpowers/specs/2026-11-05-spin-tryon-design.md`

## Global Constraints

- Video en fazla 60 MB ve 30 sn; `frames` 4–12, varsayılan 8; `category` upper/lower/overall, varsayılan upper.
- Kare çıkarma: baştan ve sondan %5 atlanır, eşit aralık, döndürme bilgisi uygulanır, ortadan 3:4 kırpılıp 768×1024.
- Arka kare: SCHP-LIP `Face` etiketi (indeks 13) piksel oranı eşiğin altındaysa `back`. Arka görsel yoksa ön görsel kullanılır.
- Kalp atışı: 30 sn GET yoksa iş iptal; tek iş toplam en fazla 15 dk; bitmiş iş 30 dk sonra silinir.
- Tek GPU kilidi: her kare `engine.run` çağrısıyla kilidi ayrı alır (mevcut `CatVTONEngine._lock`).
- Kişisel video diske kalıcı yazılmaz; PyAV bellekteki `BytesIO`'dan okur.
- Video açılamazsa 400 ve şu ipucu: "Video açılamadı. MP4/H.264 olarak kaydedin (iPhone: Ayarlar → Kamera → Formatlar → En Uyumlu)." (EN: "Could not open the video. Record as MP4/H.264 (iPhone: Settings → Camera → Formats → Most Compatible).") — backend TR döndürür, uygulama `friendlyError` ile gösterir.
- Uygulama: TR/EN ARB, mevcut tasarım belirteçleri/bileşenleri (`context.tokens`, `EditorialHeading`, `Caption`, `PillButton`, `pushEditorial`), açık/koyu tema, 360 px'de taşma yok.
- Commit mesajlarında Claude/co-author satırı yok.

## Review Focus

1. Dikey iPhone videosu (döndürme meta verisi 90°) → kareler dikey çıkmalı, yan yatmamalı. → Task 1 testi `test_rotated_video_stays_portrait`.
2. Kullanıcı işi başlattıktan sonra Safari sekmesini kapatır → GPU 30 sn içinde serbest kalmalı. → Task 3 testi `test_heartbeat_timeout_cancels`.
3. İş sürerken tek kare denemesi (`/tryon`) gelir → kaybolmamalı, en fazla bir kare beklemeli. → Task 3 testi `test_runner_called_per_frame` (her kare ayrı çağrı = kilit her kare bırakılır).
4. Polling sırasında ağ bir kez kopar (GET hatası) → ekran hata vermemeli, bir sonraki denemede devam etmeli; art arda 3 hata olursa hata göstermeli. → Task 7 testi `geçici ağ hatasında devam eder`.
5. Video seçiliyken kullanıcı fotoğraf seçer (veya tersi) → ikisi birden kalmamalı, "Üzerimde Gör" doğru akışa gitmeli. → Task 8 testi `video ve fotoğraf birbirini temizler`.

---

### Task 1: Videodan kare çıkarma (backend)

**Files:**
- Create: `backend/spin_frames.py`, `backend/requirements-dev.txt` (`pytest>=8`, `httpx>=0.27`), `backend/tests/__init__.py` (boş), `backend/tests/conftest.py` (`sys.path`'e `backend/` ekler)
- Test: `backend/tests/test_spin_frames.py`

**Interfaces:**
- Produces: `class VideoError(ValueError)`; `MAX_VIDEO_BYTES = 60 * 1024 * 1024`; `MAX_DURATION_S = 30.0`; `sample_times(duration: float, n: int, trim: float = 0.05) -> list[float]`; `extract_frames(data: bytes, n: int, size: tuple[int, int] = (768, 1024)) -> list[PIL.Image.Image]` (RGB).

- [ ] **Step 1: Install dev deps:** `backend\venv\Scripts\python.exe -m pip install -r backend\requirements-dev.txt` → pytest kurulu.
- [ ] **Step 2: Failing tests** (`test_spin_frames.py`; testler sentetik videoyu PyAV ile bellekte üretir — yardımcı `make_video(w, h, seconds, fps=30, rotate=0) -> bytes`, her kare düz renk ve kare numarasını rengine kodlar):
  - `test_sample_times_even_and_trimmed`: `sample_times(10.0, 8)` → 8 değer, ilk `0.5`, son `< 9.5`, aralıklar eşit (`pytest.approx`, `abs=1e-6`); `sample_times(10.0, 4)[0] == 0.5`.
  - `test_extract_returns_n_portrait_frames`: 3 sn, 360×640 video, `extract_frames(data, 8)` → 8 kare, hepsi `size == (768, 1024)`, RGB, ilk ve son karenin rengi farklı (zamanla değişen kareler alınmış).
  - `test_rotated_video_stays_portrait`: 640×360 video, döndürme meta verisi 90° (`stream.metadata["rotate"]="90"` veya display matrix) → çıkan kareler 768×1024 ve kaynak içerik dikey (kare yüksekliği boyunca renk değişimi beklenen yönde; en azından `extract_frames` döndürme bilgisini okuyup `Image.transpose` uygular).
  - `test_invalid_bytes_raise_video_error`: `extract_frames(b"not a video", 8)` → `VideoError`.
  - `test_too_long_raises`: 31 sn video → `VideoError` (mesajda "30").
  - `test_too_few_decodable_frames_raises`: 0,1 sn video, `n=8` → `VideoError`.
- [ ] **Step 3: Run:** `backend\venv\Scripts\python.exe -m pytest backend\tests\test_spin_frames.py -q` → FAIL (modül yok).
- [ ] **Step 4: Implement `spin_frames.py`:** `av.open(io.BytesIO(data))`; süre `stream.duration * stream.time_base` (yoksa `container.duration / av.time_base`); her hedef zamana `container.seek` + ilk kare `>=` hedef; döndürme `frame.rotation` (PyAV 18) ya da stream metadata `rotate`; `ImageOps.fit(img, size, method=LANCZOS, centering=(0.5, 0.5))` ile 3:4 kırp. Tüm `av` hataları `VideoError`'a çevrilir; mesajlar Global Constraints'teki TR metin.
- [ ] **Step 5: Run** → PASS.
- [ ] **Step 6: Commit** `feat(spin): extract evenly spaced portrait frames from a turn video`

### Task 2: Arka kare tanıma (backend)

**Files:**
- Modify: `backend/engine.py` (yeni yöntem + saf fonksiyon)
- Test: `backend/tests/test_back_view.py`

**Interfaces:**
- Produces: `LIP_FACE = 13`; `face_ratio(lip: numpy.ndarray) -> float` (Face piksel sayısı / arka plan dışı piksel sayısı; kişi yoksa 0.0); `BACK_FACE_RATIO = 0.004` (kurucu denemeyle günceller); `CatVTONEngine.is_back_view(person: Image.Image) -> bool` (kilit içinde `automasker.preprocess_image(person)["schp_lip"]` → `face_ratio < BACK_FACE_RATIO`).

- [ ] **Step 1: Failing tests** (`face_ratio` saf olduğu için GPU gerekmez):
  - `test_face_ratio_front`: 100×100 dizi, 2000 piksel kişi (değer 5), bunların 200'ü yüz (13) → `face_ratio == pytest.approx(0.1)`.
  - `test_face_ratio_back_is_zero`: kişi var, yüz yok → `0.0`.
  - `test_face_ratio_empty_is_zero`: hepsi 0 → `0.0`.
- [ ] **Step 2: Run** `pytest backend\tests\test_back_view.py -q` → FAIL. (`engine.py` CatVTON'u import ettiği için test, `face_ratio`'yu `engine` import edilmeden de kullanabilmeli → saf fonksiyonu `backend/spin_frames.py`'ye koy ve `engine.py` oradan import etsin.)
- [ ] **Step 3: Implement** `face_ratio` + sabitleri `spin_frames.py`'de, `is_back_view` `engine.py`'de.
- [ ] **Step 4: Eşik ayarı (GPU, elle):** backend kapalıyken `scratchpad/spin/out/person_*.png` (deneme kareleri) ve kendi ön fotoğrafla `is_back_view` çalıştır; ön/3/4 ön/profil `False`, arka `True` olacak şekilde `BACK_FACE_RATIO` seç; değeri ve ölçülen oranları commit mesajına yaz.
- [ ] **Step 5: Run** → PASS.
- [ ] **Step 6: Commit** `feat(spin): detect back-facing frames from SCHP face ratio`

### Task 3: İş kuyruğu (backend)

**Files:**
- Create: `backend/spin_jobs.py`
- Test: `backend/tests/test_spin_jobs.py`

**Interfaces:**
- Consumes: hiçbir GPU kodu — motor fonksiyonları dışarıdan verilir.
- Produces:
  - `Runner = Callable[[Image, Image, str], tuple[Image, float]]` (kişi, kıyafet, kategori → sonuç, süre sn); `BackCheck = Callable[[Image], bool]`.
  - `class SpinJobManager(run: Runner, is_back: BackCheck, heartbeat_s=30.0, max_job_s=900.0, keep_done_s=1800.0, clock=time.monotonic, start_thread=True)`.
  - `submit(frames: list[Image], garment_front: Image, garment_back: Image | None, category: str) -> str` (uuid4 hex).
  - `status(job_id: str, since: int = 0) -> dict` → `{"status": "queued|running|done|failed|cancelled", "total": int, "done": int, "frames": [{"index": int, "view": "front|back", "image": Image, "render_time": float}], "error": str | None}`; çağrı kalp atışını yeniler; bilinmeyen id → `KeyError`.
  - `cancel(job_id: str) -> None` (bilinmeyen id → `KeyError`).
  - `step() -> bool`: sıradaki işin bir karesini işler (veya süre/kalp atışı denetimini yapar); iş yaptıysa `True`. Thread `start_thread=True` iken `step()`'i döngüde çağırır, iş yokken 0,2 sn bekler.
  - `sweep() -> None`: kalp atışı (30 sn GET yok → `cancelled`), toplam süre (15 dk → `failed`, error "Süre aşıldı"), bitmiş işleri 30 dk sonra silme.

- [ ] **Step 1: Failing tests** (sahte `run` her çağrıyı kaydeder ve kişinin kopyasını döner; sahte saat `FakeClock` ile, `start_thread=False`):
  - `test_frames_processed_in_order`: 3 kare → 3 kez `step()` → `status` `done`, `frames` index 0,1,2.
  - `test_runner_called_per_frame`: `run` çağrı sayısı = kare sayısı (her kare ayrı çağrı).
  - `test_since_returns_only_new_frames`: 2 kare işlenmiş → `status(id, since=1)["frames"]` yalnızca index 1.
  - `test_back_frames_use_back_garment`: `is_back` index 1 için `True` → o çağrıda kıyafet `garment_back`; `view == "back"`.
  - `test_back_frames_fall_back_to_front`: `garment_back=None` → tüm çağrılarda ön görsel, `view` yine `back` bildirilir.
  - `test_cancel_stops_after_current_frame`: 1 kare sonra `cancel` → sonraki `step()` `run` çağırmaz, durum `cancelled`.
  - `test_heartbeat_timeout_cancels`: `submit` sonrası saat 31 sn ilerler, `status` çağrılmadan `sweep()` → `cancelled`; `run` hiç çağrılmaz.
  - `test_max_job_time_fails`: kalp atışı sürer ama saat 901 sn → `failed`, error "Süre aşıldı".
  - `test_done_jobs_removed_after_keep`: `done` sonrası 1801 sn → `status` `KeyError`.
  - `test_fifo_two_jobs`: iki iş; ilk iş bitmeden ikincinin karesi işlenmez, ikincinin durumu `queued`.
  - `test_runner_error_fails_job`: `run` istisna atar → `failed`, `error` istisna mesajı, sonraki iş devam eder.
- [ ] **Step 2: Run** `pytest backend\tests\test_spin_jobs.py -q` → FAIL.
- [ ] **Step 3: Implement** `spin_jobs.py` (`threading.Lock` iş sözlüğünü korur; `run` kilit DIŞINDA çağrılır ki `status` beklemesin).
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(spin): in-memory job queue with heartbeat, timeout and cancel`

### Task 4: Spin API uç noktaları (backend)

**Files:**
- Modify: `backend/main.py` (yeni uç noktalar, `spin_manager` küresel; lifespan'da motor yüklenince `SpinJobManager(run=lambda p, g, c: (lambda o: (o.image, o.render_time_sec))(engine.run(p, g, c)), is_back=engine.is_back_view)` kurulur)
- Test: `backend/tests/test_spin_api.py`

**Interfaces:**
- Consumes: Task 1 `extract_frames`, `VideoError`, `MAX_VIDEO_BYTES`; Task 3 `SpinJobManager`.
- Produces (HTTP, uygulamanın kullandığı sözleşme):
  - `POST /api/v1/spin` multipart: `video` (dosya), `garment_front` (dosya), `garment_back` (dosya, isteğe bağlı), `category` (form, "upper"), `frames` (form, 8). → 200 `{"job_id": str, "total": int}`; 400 `{"detail": str}` (geçersiz kategori, `frames` 4–12 dışı, video > 60 MB, `VideoError`, okunamayan görsel); 503 motor yüklenmemişken.
  - `GET /api/v1/spin/{job_id}?since=0` → 200 `{"status", "total", "done", "frames": [{"index", "view", "image_base64" (PNG), "render_time"}], "error"}`; 404 bilinmeyen id.
  - `DELETE /api/v1/spin/{job_id}` → 200 `{"status": "cancelled"}`; 404.

- [ ] **Step 1: Failing tests** (`fastapi.testclient.TestClient(main.app)` — `with` kullanılmaz, lifespan çalışmaz; `main.engine` sahte bir nesneyle (`normalize_category` gerçek sınıf metodu) ve `main.spin_manager` `start_thread=False` bir `SpinJobManager` ile monkeypatch'lenir; video Task 1'deki `make_video` ile):
  - `test_post_returns_job_and_total`: 2 sn video + PNG kıyafet → 200, `total == 8`.
  - `test_post_frames_param`: `frames=4` → `total == 4`; `frames=3` ve `13` → 400.
  - `test_post_bad_video_400_with_hint`: bozuk video → 400, `detail` içinde "En Uyumlu".
  - `test_post_too_large_400`: `MAX_VIDEO_BYTES` monkeypatch ile 1000 yapılıp 2000 baytlık gövde → 400.
  - `test_post_engine_missing_503`: `main.engine = None` → 503.
  - `test_get_returns_base64_frames_since`: `step()` iki kez → `GET ?since=1` tek kare, `image_base64` PNG olarak çözülebilir.
  - `test_get_unknown_404` / `test_delete_unknown_404`.
  - `test_delete_cancels`: DELETE → 200; ardından GET `status == "cancelled"`.
- [ ] **Step 2: Run** `pytest backend\tests -q` → yeni testler FAIL.
- [ ] **Step 3: Implement** uç noktaları (`await asyncio.to_thread(extract_frames, data, frames)`; görselleri mevcut `_read_image` ile oku; PNG base64 için mevcut `_encode`).
- [ ] **Step 4: Run** `pytest backend\tests -q` → hepsi PASS.
- [ ] **Step 5: Smoke (GPU):** backend'i başlat, `tests/api_spin.py` (yeni, `tests/api_tryon.py` kalıbında) ile örnek videoyla iş başlat, durum sorgula, ilk karenin ~45 sn'de geldiğini ve `view` değerlerini yazdır. Örnek video yoksa: denemedeki 4 kişi karesinden 2 fps'lik 4 sn'lik MP4 üret (betikte `--from-images` seçeneği).
- [ ] **Step 6: Commit** `feat(spin): POST/GET/DELETE /api/v1/spin`

### Task 5: Uygulama API istemcisi ve modeller

**Files:**
- Create: `see_it_on/lib/models/spin.dart`
- Modify: `see_it_on/lib/services/api_service.dart`
- Test: `see_it_on/test/spin_model_test.dart`

**Interfaces:**
- Produces:
  - `class SpinFrame { final int index; final String view; final Uint8List bytes; final double renderTimeSec; bool get isBack; }`
  - `enum SpinState { queued, running, done, failed, cancelled }`
  - `class SpinStatus { final SpinState state; final int total; final int done; final List<SpinFrame> frames; final String? error; factory SpinStatus.fromJson(Map<String, dynamic>); bool get isFinished; }` (bilinmeyen durum → `failed`)
  - `class SpinRequest { final Uint8List videoBytes; final String videoName; final Uint8List garmentFront; final Uint8List? garmentBack; final String category; final int frames; }` (`frames` varsayılan 8)
  - `ApiService.startSpin(SpinRequest) -> Future<String>` (job id; 400/503'te `detail` ile `Exception`), `ApiService.spinStatus(String jobId, {int since = 0}) -> Future<SpinStatus>`, `ApiService.cancelSpin(String jobId) -> Future<void>` (hataları yutar). POST zaman aşımı 120 sn, GET 15 sn.

- [ ] **Step 1: Failing tests:** `SpinStatus.fromJson` örnek JSON (2 kare, biri `back`, base64 PNG) → `state == SpinState.running`, `frames[1].isBack`, `bytes` çözülmüş; `"status":"weird"` → `failed`; `isFinished` done/failed/cancelled için true.
- [ ] **Step 2: Run** `flutter test test/spin_model_test.dart` → FAIL.
- [ ] **Step 3: Implement** modeller ve üç `ApiService` yöntemi (mevcut `processVirtualTryOn` kalıbı: `http.MultipartRequest`, `_errorMessage`).
- [ ] **Step 4: Run** → PASS; `flutter analyze` temiz.
- [ ] **Step 5: Commit** `feat(spin): API client and models`

### Task 6: `SpinViewer` görüntüleyici

**Files:**
- Create: `see_it_on/lib/widgets/spin_viewer.dart`
- Test: `see_it_on/test/spin_viewer_test.dart`

**Interfaces:**
- Produces: `class SpinViewer extends StatefulWidget { const SpinViewer({super.key, required List<ImageProvider> frames, SpinViewerController? controller}); }`; `class SpinViewerController extends ChangeNotifier { double get position; void play(); void stop(); bool get isPlaying; }` — `position` 0 ≤ p < kare sayısı, sürekli; görüntü `floor(p)` ve `ceil(p) % n` karelerinin `p - floor(p)` saydamlıkla karışımı. Genişliğin tamamı kadar sürükleme = tam tur. `play()` tam turu 4 sn'de oynatır ve durur. Kare listesi büyüdüğünde konum korunur.

- [ ] **Step 1: Failing tests** (1×1 PNG `MemoryImage`'lar):
  - `sürükleme kareyi değiştirir`: 8 kare, 400 px genişlik, 50 px sola sürükle → `controller.position == closeTo(1.0, 0.05)` (sola sürükleme saat yönünde ileri).
  - `tam genişlik tam tur`: 400 px sürükleme → `position == closeTo(0, 0.05)` (sarar).
  - `tek karede döndürme yok`: 1 kare, sürükleme → `position == 0`, `play()` sonrası `isPlaying == false`.
  - `play tam turu 4 saniyede bitirir`: `play()`, `pump(4.1 sn)` → `isPlaying == false`, `position closeTo(0)`.
  - `kare eklenince konum korunur`: 4 kare, konum 2, liste 8 kareye çıkar → `position == 2`.
  - Taşma: 360×800, açık/koyu, `expectNoOverflow`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** (`GestureDetector.onHorizontalDragUpdate`, `AnimationController` 4 sn, `Stack` + iki `Image` + `Opacity`; `gaplessPlayback: true`).
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(spin): drag-to-rotate spin viewer`

### Task 7: `SpinScreen` (ilerleme, polling, iptal, hazır set)

**Files:**
- Create: `see_it_on/lib/screens/spin_screen.dart`
- Modify: `see_it_on/lib/l10n/app_tr.arb`, `app_en.arb`
- Test: `see_it_on/test/spin_screen_test.dart`

**Interfaces:**
- Consumes: Task 5 `ApiService`, `SpinRequest`, `SpinStatus`; Task 6 `SpinViewer`.
- Produces: `class SpinScreen extends StatefulWidget { const SpinScreen.live({required SpinRequest request, ApiService? api, Duration pollEvery = const Duration(seconds: 3)}); const SpinScreen.preset({required List<ImageProvider> frames, required String title}); }`.
- ARB (TR / EN): `spinTitle` "360° Dönüş" / "360° Spin"; `spinProgress` "{done} / {total} kare hazır" / "{done} of {total} frames ready"; `spinEta` "Yaklaşık {minutes} dk kaldı" / "About {minutes} min left"; `spinPlay` "Döndür" / "Spin"; `spinStop` "Durdur" / "Stop"; `spinDragHint` "Döndürmek için sağa sola kaydır" / "Drag left or right to rotate"; `spinFailed` "Dönüş oluşturulamadı: {reason}" / "Could not create the spin: {reason}"; `spinCancelled` "İşlem iptal edildi." / "The job was cancelled."; `spinStarting` "Video gönderiliyor…" / "Uploading the video…".

- [ ] **Step 1: Failing tests** (sahte `ApiService` `implements`, `noSuchMethod`; `pollEvery: Duration(milliseconds: 10)`):
  - `kareler geldikçe gösterilir`: sahte durumlar running(1/8) → running(3/8) → done(8/8); metin `l.spinProgress(3, 8)` görünür, sonunda `SpinViewer` 8 kare, "Döndür" etkin.
  - `since ile yalnızca yeni kareler istenir`: ikinci çağrıda `since == 1`, üçüncüde `3`.
  - `çıkışta iş iptal edilir`: iş sürerken geri → `cancelSpin(jobId)` çağrıldı.
  - `bitmiş işte çıkışta iptal yok`: done sonrası geri → `cancelSpin` çağrılmadı.
  - `başarısız iş hata gösterir`: failed + error "x" → `l.spinFailed('x')`.
  - `geçici ağ hatasında devam eder`: `spinStatus` bir kez istisna, sonra running → hata metni yok, ilerleme sürüyor; art arda 3 istisna → `spinFailed` gösterilir.
  - `hazır set hemen döner`: `SpinScreen.preset(frames: 7 kare)` → api çağrısı yok, `SpinViewer` 7 kare, ilerleme metni yok.
  - Taşma: canlı ekran TR/açık ve EN/koyu 360 px.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** (ARB ekle + `flutter gen-l10n`; `Timer.periodic` dispose'da iptal; tahmini kalan süre = ortalama `renderTimeSec` × kalan kare; çıkışta iş bitmemişse `cancelSpin`).
- [ ] **Step 4: Run** → PASS; `flutter analyze` temiz.
- [ ] **Step 5: Commit** `feat(spin): spin screen with live progress, cancel on leave, preset mode`

### Task 8: Ana ekran bağlantısı ve hazır set kartı

**Files:**
- Modify: `see_it_on/lib/screens/home_screen.dart`, ARB dosyaları, `see_it_on/pubspec.yaml` (`assets/images/spin/demo/`)
- Create: `see_it_on/lib/models/spin_preset.dart`
- Test: `see_it_on/test/home_spin_test.dart`

**Interfaces:**
- Consumes: Task 7 `SpinScreen.live/.preset`, Task 5 `SpinRequest`.
- Produces: `class SpinPreset { final String titleTr, titleEn; final List<String> framePaths; static Future<SpinPreset?> load(AssetBundle bundle, {String dir = 'assets/images/spin/demo'}); }` (manifest yoksa `null` → kart gizli). `manifest.json`: `{"title_tr": str, "title_en": str, "frames": int}`; kare dosyaları `frame_0.jpg`…`frame_{n-1}.jpg`.
- ARB: `homeSpinVideo` "Dönüş videosu" / "Turn video"; `homeSpinSelected` "360° dönüş videosu" / "360° spin video"; `homeGarmentBack` "Arka görsel (isteğe bağlı)" / "Back image (optional)"; `homeSpinPreset` "Hazır 360° set" / "Ready-made 360° set"; `homeSpinHint` "Ayakların sabit, yavaşça tam tur dön (10–20 sn)" / "Keep your feet in place and turn slowly (10–20 s)".

- [ ] **Step 1: Failing tests** (`HomeScreen`'e test için `ImagePicker`'ı soyutlayan isteğe bağlı parametre ekle: `HomeScreen({super.key, MediaPicker? picker})`, `abstract class MediaPicker { Future<XFile?> pickImage(ImageSource); Future<XFile?> pickVideo(ImageSource); }`):
  - `video seçilince dönüş etiketi ve arka görsel alanı görünür`.
  - `video ve fotoğraf birbirini temizler`: video seç → Galeri ile fotoğraf seç → dönüş etiketi kaybolur; tersi de.
  - `video varken Üzerimde Gör SpinScreen açar`, yoksa `LoadingScreen` (mevcut davranış; `find.byType`).
  - `hazır set kartı manifest varsa manken seçicide görünür` (sahte `AssetBundle`), yoksa görünmez; dokununca `SpinScreen` açılır.
  - Taşma: video seçili ana ekran TR/açık ve EN/koyu 360 px.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.** Video süresi gösterilmez (`video_player` gerektirir; ilk sürümde gerek yok). Hazır set kartı manken seçici alt sayfasının en üstünde, manken ızgarasından önce durur; dokununca alt sayfa kapanır ve `SpinScreen.preset` açılır. 1. adım kartındaki düğmeler: Galeri, Kamera, Manken, Dönüş videosu (Wrap, mevcut `_buildCardButton`).
- [ ] **Step 4: Run** `flutter test` → hepsi PASS; `flutter analyze` temiz.
- [ ] **Step 5: Commit** `feat(spin): turn-video input, optional back image and preset card on home`

### Task 9: Hazır sunum seti (içerik, GPU, kullanıcı onayı)

**Files:**
- Create: `tools/make_spin_set.py`, `see_it_on/assets/images/spin/demo/manifest.json`, `frame_0.jpg`…
- Kaynaklar (git dışı): `test_images/spin/person/01_front34.png …`, `test_images/spin/garment_front.png`, `garment_back.png`

**Interfaces:**
- `python tools/make_spin_set.py <kişi klasörü> <ön görsel> [--back arka] [--mirror] [--out see_it_on/assets/images/spin/demo] [--title-tr ...] [--title-en ...]`: kişi görsellerini ada göre sıralar; her birini `CatVTONEngine.run` ile giydirir (adı `back` içeren ya da `is_back_view` True olanlara arka görsel); `--mirror` ile son kare hariç ters sırada aynalanmış kopyaları ekler (ön34, yan, arka34, arka, arka34', yan', ön34' = 7); 768×1024 JPEG (kalite 90) + `manifest.json` yazar.

- [ ] **Step 1:** Kişi açılarını hazırla: denemedeki `turn_22.png`'den 3/4 ön, profil, 3/4 arka, arka figürlerini temiz kırp (komşu figürler arka plan rengiyle kapatılır), `test_images/spin/person/`'a koy; gerekirse 1–2 yeni dönüş sayfası tohumu dene.
- [ ] **Step 2:** Kıyafet çifti: aynı tohum ve aynı kumaş tarifiyle 3–4 ön/arka çifti üret, en tutarlı çifti seç (desen ve renk aynı).
- [ ] **Step 3:** `make_spin_set.py`'yi çalıştır (backend kapalıyken).
- [ ] **Step 4: Kullanıcı onayı:** 7 kareyi ve dönen önizlemeyi (GIF) kullanıcıya göster; onay gelmeden `assets/`'e commit yok.
- [ ] **Step 5: Commit** `feat(spin): ready-made 360° demo set`

### Task 10: Uçtan uca kontrol ve teslim

- [ ] **Step 1:** `backend\venv\Scripts\python.exe -m pytest backend\tests -q` ve `flutter test` / `flutter analyze` → hepsi temiz.
- [ ] **Step 2:** Web release derle, iPhone Safari (`http://172.20.10.2:8080`): hazır set anında açılır ve döner; gerçek dönüş videosuyla (kullanıcı çeker) iş başlar, ilk kare ~45 sn'de görünür, ekrandan çıkınca backend logunda iptal görünür.
- [ ] **Step 3:** `docs/ROADMAP.md` çoklu açı maddesini güncelle; `docs/KNOWN_LIMITATIONS.md`'ye titreme ve HEVC notunu ekle; commit; push; PR aç.
