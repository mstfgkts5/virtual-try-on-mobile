# Architecture Overview

Proje dört ana katmandan oluşmaktadır:

1. **Mobile Client (Flutter):** Kullanıcı arayüzü, kamera/galeri erişimi ve durum yönetimi.
2. **Backend API (Python / FastAPI):** Mobil uygulamadan gelen istekleri karşılayan, veritabanı işlemlerini yöneten ve AI modeline köprü görevi gören sunucu.
3. **AI Engine:** Görsel birleştirme işlemlerini gerçekleştiren yapay zeka difüzyon modeli (Örn: IDM-VTON).
4. **Database (Supabase):** Kimlik doğrulama ve veri saklama.

## Sequence Diagram

Aşağıdaki diyagram, kullanıcının fotoğraf yüklemesinden yapay zeka modelinin sonuç döndürmesine kadar geçen asenkron süreci göstermektedir.

```mermaid
sequenceDiagram
    actor U as Kullanıcı (Flutter)
    participant API as FastAPI Backend
    participant DB as Supabase
    participant AI as IDM-VTON Engine

    U->>API: 1. Fotoğraf ve Kıyafet ID'sini Gönder (POST)
    activate API
    API->>DB: 2. İsteği Veritabanına Kaydet (Status: Pending)
    activate DB
    DB-->>API: 3. Kayıt Başarılı
    deactivate DB
    API->>AI: 4. Görselleri İşlenmek Üzere Gönder
    activate AI
    API-->>U: 5. İşlem Başladı Yanıtı (202 Accepted)
    deactivate API
    
    Note over U: Kullanıcıya Yükleme Ekranı Gösterilir
    
    AI-->>API: 6. İşlenmiş Görseli Döndür
    deactivate AI
    activate API
    API->>DB: 7. Durumu Güncelle (Status: Completed) ve Görsel URL'ini Kaydet
    API-->>U: 8. İşlem Tamamlandı Bildirimi (WebSocket/Polling)
    deactivate API
    U->>U: 9. Sonucu Ekranda Göster

## Use Case Diagram

Sistemin temel aktörleri ve kullanım senaryoları.

```mermaid
usecaseDiagram
    actor Kullanıcı as "Mobil Kullanıcı"
    actor Admin as "Sistem Yöneticisi"
    
    package "Virtual Try-On App" {
        usecase "Kayıt Ol / Giriş Yap" as UC1
        usecase "Katalogdan Kıyafet Seç" as UC2
        usecase "Kendi Fotoğrafını Yükle" as UC3
        usecase "Sanal Deneme (Try-On) Başlat" as UC4
        usecase "Sonucu Favorilere Ekle" as UC5
        usecase "Kıyafet Katalogunu Güncelle" as UC6
    }
    
    Kullanıcı --> UC1
    Kullanıcı --> UC2
    Kullanıcı --> UC3
    Kullanıcı --> UC4
    Kullanıcı --> UC5
    
    Admin --> UC6