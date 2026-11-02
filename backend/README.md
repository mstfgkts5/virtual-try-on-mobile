# SeeItOn - Yerel Sanal Deneme Backend'i (FastAPI + CatVTON)

Bu servis, **SeeItOn** Flutter uygulamasından gelen kişi ve kıyafet fotoğraflarını alır ve
**CatVTON** difüzyon modeliyle yerel NVIDIA GPU üzerinde sanal deneme yapar.
Üst giyim (`upper`), alt giyim (`lower`) ve tam kıyafet (`overall`) desteklenir.

Ölçülen performans (RTX 5060 Laptop, 8 GB): görsel başına ~40 sn (30 adım), en yüksek VRAM ~4,4 GB.

---

### 1. Kurulum

```bash
# Proje kökünde: CatVTON kaynak kodu
git clone --depth 1 https://github.com/Zheng-Chong/CatVTON.git ai/CatVTON

cd backend
python -m venv venv
venv\Scripts\pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128
venv\Scripts\pip install -r requirements.txt

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
| `steps` | sayı | 10–50 arası difüzyon adımı (varsayılan 30) |
| `seed` | sayı | Tekrarlanabilir sonuç için (varsayılan 42) |

Yanıt: `image/png`. `X-Render-Time` başlığı gerçek işlem süresini (sn), `X-Category` kullanılan kategoriyi verir.

---

### 4. Flutter Uygulaması ile Bağlantı

- **Chrome / Web**: `http://localhost:8000`
- **Android Emülatör**: `http://10.0.2.2:8000`
- **Gerçek Telefon**: Bilgisayarın yerel Wi-Fi IP adresi (örn. `http://192.168.1.35:8000`), uygulamadaki ayarlardan girilir.

---

### 5. Test

```bash
backend\venv\Scripts\python tests\smoke_tryon.py <kişi.jpg> <kıyafet.jpg> upper
```
