# SeeItOn - AI Virtual Try-On Python FastAPI Backend

Bu servis, **SeeItOn** Flutter mobil uygulamasından gelen iki görseli (`person_image` ve `garment_image`) alır ve **IDM-VTON** yapay zeka difüzyon modeline ileterek 1. fotoğraftaki kişinin üzerine 2. fotoğraftaki kıyafeti giydirilmiş şekilde döndürür.

---

### 1. Kurulum

Gerekli Python paketlerini yükleyin:

```bash
cd backend
pip install -r requirements.txt
```

---

### 2. Sunucuyu Başlatma

Sunucuyu yerel makinenizde çalıştırmak için:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Sunucu başladığında `http://localhost:8000/docs` adresinden interaktif Swagger dokümantasyonunu görebilirsiniz.

---

### 3. Flutter Uygulaması ile Bağlantı

- **Chrome / Web**: Otomatik olarak `http://localhost:8000` üzerinden bağlanır.
- **Android Emülatör**: `http://10.0.2.2:8000` üzerinden bağlanır.
- **Gerçek Telefon**: Bilgisayarınızın yerel Wi-Fi IP adresini (Örn: `http://192.168.1.35:8000`) veya Ngrok linkini mobil uygulamanın sağ üstündeki **Profil (Ayarlar)** penceresinden girebilirsiniz.

---

### 4. Model Çalışma Mantığı

1. `gradio_client` sayesinde doğrudan Hugging Face üzerindeki açık **`yisol/IDM-VTON`** Space'ini çağırır. Bu sayede yerel bilgisayarınızda pahalı bir NVIDIA ekran kartına ihtiyaç duymadan gerçek difüzyon çıktısı alabilirsiniz.
2. İnternet kesilirse veya Hugging Face kota sınırına girerse, sunucu otomatik olarak Pillow katmanlı kompozit motorunu devreye sokar ve hiçbir zaman çökme yaşanmaz.
