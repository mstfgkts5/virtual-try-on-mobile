# SeeItOn - Yerel Sanal Deneme Backend'i (FastAPI + CatVTON)

Bu servis, **SeeItOn** Flutter uygulamasından gelen kişi ve kıyafet fotoğraflarını alır ve
**CatVTON** difüzyon modeliyle yerel NVIDIA GPU üzerinde sanal deneme yapar.
Üst giyim (`upper`), alt giyim (`lower`) ve tam kıyafet (`overall`) desteklenir.

Ölçülen performans (RTX 5060 Laptop, 8 GB, şarjda): görsel başına ~5 sn (DPM-Solver++ 8 adım, 576×768), en yüksek VRAM ~3,7 GB. Ayrıntı: `docs/PERFORMANCE.md`.

---

### 1. Kurulum

```bash
# Proje kökünde: CatVTON kaynak kodu
git clone --depth 1 https://github.com/Zheng-Chong/CatVTON.git ai/CatVTON

cd backend
python -m venv venv
venv\Scripts\pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128
venv\Scripts\pip install -r requirements.txt
# Birebir aynı sürümler için (tekrarlanabilir kurulum): pip install -r requirements.lock

# CatVTON'u raporda ölçülen sürüme sabitlemek için:
git -C ..\ai\CatVTON fetch --depth 1 origin 7818397f25613beedb3d861a34769f607cfcf3b1 && git -C ..\ai\CatVTON checkout 7818397f25613beedb3d861a34769f607cfcf3b1

# Model ağırlıkları (~6 GB, kullanıcının Hugging Face önbelleğine iner)
set HF_HUB_DISABLE_XET=1
venv\Scripts\python download_models.py
```

---

### 2. Sunucuyu Başlatma

```bash
cd backend
venv\Scripts\python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Model açılışta bir kez GPU'ya yüklenir (~20 sn). `GET /health` model hazır olunca `"status": "ok"` döner.
Swagger dokümantasyonu: `http://localhost:8000/docs`

---

### 3. API

`POST /api/v1/tryon` (multipart/form-data)

| Alan | Tür | Açıklama |
|---|---|---|
| `person_image` | dosya | Kişi fotoğrafı (önden, tercihen boydan) |
| `garment_image` | dosya | Kıyafet fotoğrafı (düz zemin) |
| `category` | metin | `upper`, `lower` veya `overall` (varsayılan `upper`) |
| `steps` | sayı | 4–50 arası difüzyon adımı (varsayılan 8, DPM-Solver++) |
| `preview` | bool | `true`: canlı önizleme (384×512, 3 adım, JPEG) |
| `seed` | sayı | Tekrarlanabilir sonuç için (varsayılan 42) |

Yanıt (JSON):

| Alan | Açıklama |
|---|---|
| `image_base64` | Sonuç görseli (PNG, 576×768; önizlemede JPEG 384×512) |
| `person_base64` | Modele giren 3:4 kırpılmış kişi fotoğrafı (JPEG); önce/sonra karşılaştırması bununla yapılır |
| `category` | Kullanılan kategori (`upper` / `lower` / `overall`) |
| `render_time` | Gerçek işlem süresi (sn) |
| `width`, `height` | Sonuç boyutu |

---

### 4. Flutter Uygulaması ile Bağlantı

- **Chrome / Web**: `http://localhost:8000`
- **Android Emülatör**: `http://10.0.2.2:8000`
- **Gerçek Telefon**: Bilgisayarın yerel Wi-Fi IP adresi (örn. `http://192.168.1.35:8000`), uygulamadaki ayarlardan girilir.

---

### 5. Docker (isteğe bağlı)

```bash
docker build -f backend/Dockerfile -t seeiton-backend .
docker run --gpus all -p 8000:8000 -v seeiton-hf:/root/.cache/huggingface seeiton-backend
```

### 6. Test

```bash
backend\venv\Scripts\python tests\smoke_tryon.py <kişi.jpg> <kıyafet.jpg> upper
```
