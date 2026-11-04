# Supabase kurulumu

Uygulamanın gardırop özelliği için Supabase projesinde **bir kez** yapılacaklar:

1. **Authentication → Sign In / Providers → Email → "Confirm email"** kapalı olmalı (kayıt olan kullanıcı hemen giriş yapar).
2. **SQL Editor → New query** → [`setup_wardrobe.sql`](setup_wardrobe.sql) içeriğini yapıştır → **Run**.
   - `wardrobe` tablosuna `category` sütunu ekler,
   - her kullanıcının yalnızca kendi kombinlerine erişmesini sağlar (RLS),
   - `wardrobe_images` görsel deposunu ve yükleme/silme kurallarını oluşturur.

SQL çalıştırılmadan da uygulama açılır; ancak kategori bilgisi kaydedilmez (hepsi "Üst Giyim" görünür) ve depo yoksa görsel yükleme başarısız olur.

## Kontrol
Uygulamada giriş yap → bir kombin dene → sonuç ekranında **Gardıroba Ekle** → alt menüden **Gardırop**: kombin kategorisiyle listelenmeli; detayından silinebilmeli.
