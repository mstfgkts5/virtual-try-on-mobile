# Akıcı 360° Dönüş (ara kareler + eylemsizlik) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Dönüşü gerçek bir insan dönüyormuş gibi akıcı göstermek: 12 giydirilmiş ana kare + aralarına RIFE ile 3'er ara kare (48 kare), sürüklemede eylemsizlik.

**Architecture:** `SpinJobManager` her yeni ana kareden sonra dışarıdan verilen `interpolate(a, b, n) -> list[Image]` fonksiyonuyla önceki ana kare ile arasına ara kareler ekler; son ana kare bitince son→ilk arası da eklenir (tur kapanır). Kareler genişletilmiş sırada (`index`) ve `kind` (key/tween) ile döner; `since` sözleşmesi değişmez. RIFE (`backend/rife_ifnet.py`, MIT) motorla birlikte bir kez GPU'ya yüklenir.

**Spec:** Kullanıcıyla onaylanan kısa tasarım (konuşma, 2026-11-07) + `docs/superpowers/specs/2026-11-05-spin-tryon-design.md`.

## Global Constraints
- Ana kare varsayılanı 12 (aralık 4–16); ara kare sayısı 3 (`TWEENS = 3`).
- Genişletilmiş indeks: ana kare `k` → `k * (TWEENS + 1)`; `k` ile `k+1` arası ara kareler `k*(T+1)+1 … k*(T+1)+T`; son→ilk arası en sonda.
- RIFE girişleri 32'nin katı boyutta (576×768 uygundur); fp16, CUDA.
- Hata: interpolasyon başarısız olursa iş durmaz, o aralık ara karesiz kalır ve sıra yine bitişik olur (ara kareler yerine ana karenin kopyası değil, aralık atlanır → indeksler sıkıştırılmaz; bu yüzden başarısızlıkta ara kare yerine iki ana karenin doğrusal karışımı kullanılır).
- Commit mesajlarında Claude satırı yok.

## Review Focus
1. Polling sırasında ara karelerin bitişik sırayla gelmesi (`since` atlamamalı). → Task 1 `test_tweens_keep_indices_contiguous`.
2. İş iptal edilirse son→ilk ara kareleri üretilmemeli. → Task 1 `test_cancel_skips_closing_tweens`.
3. RIFE hatası işi düşürmemeli. → Task 1 `test_interpolate_error_falls_back_to_blend`.
4. 1 ana karelik iş (tek kare) → ara kare yok. → Task 1 `test_single_key_no_tweens`.
5. Eylemsizlik: hızlı kaydırıp bırakınca dönmeye devam edip durmalı; dokununca durmalı. → Task 4 testleri.

---

### Task 1: Kuyrukta ara kareler
**Files:** Modify `backend/spin_jobs.py`; Test `backend/tests/test_spin_jobs.py`
**Interfaces:** `Interpolator = Callable[[Image, Image, int], list[Image]]`; `SpinJobManager(..., interpolate: Interpolator | None = None, tweens: int = 3)`; sonuç karesi `{"index", "kind": "key"|"tween", "view", "image", "render_time"}`; `status()["total"]` = genişletilmiş toplam (`n*(T+1)` veya ara kare yoksa `n`).
- [ ] Testler: `test_tweens_inserted_between_keys` (3 ana kare, sahte interpolate → indeks 0..11, kind sırası key,t,t,t,key,…, son 3'ü kapanış), `test_tweens_keep_indices_contiguous`, `test_cancel_skips_closing_tweens`, `test_interpolate_error_falls_back_to_blend`, `test_single_key_no_tweens`, `test_without_interpolator_unchanged` (mevcut davranış).
- [ ] RED → uygula → GREEN → commit `feat(spin): insert interpolated tween frames between keys`

### Task 2: RIFE ara kare üretici
**Files:** Create `backend/interpolator.py`; Modify `backend/engine.py` (yükleme + `interpolate`), `backend/download_models.py`; Test `backend/tests/test_interpolator.py`
**Interfaces:** `class RifeInterpolator: __init__(weights_path, device="cuda")`, `between(a: Image, b: Image, n: int) -> list[Image]` (n=3 → t=0.25,0.5,0.75 orta nokta özyinelemesiyle; boyut 32'nin katına pad/kırp, çıktı girdiyle aynı boyut); `CatVTONEngine.interpolate(a, b, n)`.
- [ ] Test (CPU, rastgele ağırlıklı küçük IFNet yerine saf yardımcılar): `test_pad_to_32` boyut yuvarlama, `test_order_of_midpoints` (n=3 için çağrı sırası t=.25,.5,.75), GPU'lu smoke elle.
- [ ] Commit `feat(spin): RIFE interpolator loaded with the engine`

### Task 3: API
**Files:** Modify `backend/main.py`; Test `backend/tests/test_spin_api.py`
- [ ] `frames` varsayılan 12, aralık 4–16; GET karelerine `kind`; JPEG (q=90) gönderim (inceleme küçük bulgusu). Testler güncellenir.
- [ ] Commit `feat(spin): 12 key frames, tween kind and JPEG frames in API`

### Task 4: Uygulama
**Files:** Modify `see_it_on/lib/models/spin.dart` (`kind`, `isTween`), `see_it_on/lib/widgets/spin_viewer.dart` (eylemsizlik), `SpinRequest.frames` varsayılan 12; Test `spin_model_test.dart`, `spin_viewer_test.dart`.
- [ ] Testler: `kind` çözümü; `fırlatınca dönmeye devam eder` (fling sonrası konum sürüklemeden fazla ilerler ve sonunda durur), `dokununca eylemsizlik durur`.
- [ ] Commit `feat(spin): fling inertia and tween-aware frames`

### Task 5: Hazır set ara kareli
**Files:** Modify `tools/make_spin_set.py` (`--tweens 3`), yeniden üret; kullanıcıya göster, onayla commit.

### Task 6: Kontrol
- [ ] pytest + flutter test/analyze; GPU smoke (`tests/api_spin.py`); web derle; ROADMAP/KNOWN_LIMITATIONS; push; PR #8 güncellenir.
