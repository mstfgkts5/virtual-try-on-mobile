# Supabase kurulumu

Uygulamanın gardırop özelliği için Supabase projesinde **bir kez** yapılacaklar:

1. **Authentication → Sign In / Providers → Email → "Confirm email"** kapalı olmalı (kayıt olan kullanıcı hemen giriş yapar).
2. **SQL Editor → New query** → [`setup_wardrobe.sql`](setup_wardrobe.sql) içeriğini yapıştır → **Run**.
   - `wardrobe` tablosuna `category` sütunu ekler,
   - her kullanıcının yalnızca kendi kombinlerine erişmesini sağlar (RLS); `wardrobe` tablosundaki **eski/başka kuralları kaldırır** (kaldırılanlar çıktıda NOTICE olarak görünür),
   - `wardrobe_images` görsel deposunu ve yükleme/silme kurallarını oluşturur.

3. **SQL Editor → New query** → [`privacy_setup.sql`](privacy_setup.sql) → **Run** (KVKK):
   - `wardrobe_images` deposunu **özel** yapar; uygulama görselleri 1 saat geçerli imzalı URL ile gösterir,
   - Ayarlar'daki **Hesabımı ve verilerimi sil** için `delete_user()` fonksiyonunu ekler (yalnızca çağıran kullanıcının hesabını siler).

SQL çalıştırılmadan da uygulama açılır; ancak kategori bilgisi kaydedilmez (hepsi "Üst Giyim" görünür) ve depo yoksa görsel yükleme başarısız olur.

## Kontrol
Uygulamada giriş yap → bir kombin dene → sonuç ekranında **Gardıroba Ekle** → alt menüden **Gardırop**: kombin kategorisiyle listelenmeli; detayından silinebilmeli.
