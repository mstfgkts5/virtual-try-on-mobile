# SeeItOn - Virtual Try-On Mobile Application

SeeItOn, kullanıcıların seçtikleri kıyafetleri kendi fotoğrafları (veya hazır mankenler) üzerinde fotogerçekçi şekilde denemelerini sağlayan yapay zeka destekli bir sanal kabin uygulamasıdır. Yapay zeka modeli **bulutta değil, yerel GPU üzerinde** çalışır.

## Özellikler
* **Üst giyim, alt giyim ve tam kıyafet** denemesi (tek model: CatVTON)
* **Hazır mankenler:** kadın (160 cm) ve erkek (185 cm), S / M / L / XL bedenler
* **Önce / sonra karşılaştırması:** sürgü, yan yana ve geçiş modları
* Gerçek işlem süresi gösterimi, galeriye kaydetme ve paylaşma
* Supabase ile kullanıcı girişi ve dijital gardırop

## Teknolojiler
* **Mobil:** Flutter
* **Backend:** FastAPI (Python), Uvicorn
* **Yapay Zeka:** [CatVTON](https://github.com/Zheng-Chong/CatVTON) (difüzyon tabanlı sanal deneme), DensePose + SCHP ile vücut maskesi
* **Veritabanı & Auth:** Supabase
* **Test verisi:** Mankenler ve örnek kıyafetler RealVisXL V5 ile üretildi (gerçek kişi / marka ürünü kullanılmadı)

## Performans
RTX 5060 Laptop GPU (8 GB) üzerinde: görsel başına ~40 sn (30 difüzyon adımı), en yüksek VRAM ~4,4 GB.

## Klasör Yapısı
| Klasör | İçerik |
|---|---|
| `see_it_on/` | Flutter uygulaması |
| `backend/` | FastAPI sunucusu ve CatVTON motoru (`engine.py`) — kurulum: [backend/README.md](backend/README.md) |
| `tools/` | Manken ve örnek kıyafet üretim betikleri |
| `tests/` | Backend motor ve API testleri |
| `docs/` | Yol haritası ve proje belgeleri |
| `research/` | Fizibilite ve rakip analizi |

## Supabase Kurulumu (bir kez)
Gardırop için Supabase SQL Editor'da [`supabase/setup_wardrobe.sql`](supabase/setup_wardrobe.sql) çalıştırılır; ayrıntılar [`supabase/README.md`](supabase/README.md).

## Hızlı Başlangıç
```bash
# 1) Backend (model ilk açılışta GPU'ya yüklenir)
backend\venv\Scripts\python -m uvicorn main:app --host 0.0.0.0 --port 8000 --app-dir backend

# 2) Uygulama
cd see_it_on
flutter run -d chrome
```

## Bilinen Sınırlar
* Hedef alt giyim, fotoğraftaki mevcut kıyafetten kısaysa (ör. tayt üzerine şort) sonuç uzayabilir; CatVTON giydirilecek bölgeyi mevcut kıyafete göre belirler.
* Model önden çekilmiş fotoğraflarla en iyi sonucu verir.
