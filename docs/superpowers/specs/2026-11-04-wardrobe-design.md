# SeeItOn — Gardırop Yeniden Tasarım ve Supabase Bağlantısı (Tasarım)

Tarih: 2026-11-04 · Durum: kullanıcı tüm kararları Claude'a bıraktı ("tüm düzenlemeleri yap, her şeyi onaylıyorum"); kararlar aşağıda "Claude'un kararı" olarak işaretli.

## Amaç
Gardırop, kullanıcının **kendi denediği ve kaydettiği** kombinleri göstersin; uygulamanın geri kalanıyla aynı görsel dilde olsun.

## Mevcut durum (inceleme)
- Ekran koyu tema (uygulama krem), internetten çekilen alakasız örnek fotoğraflar, Supabase'den hiç okumuyor.
- Supabase `wardrobe` tablosu: `id, user_id, image_url, created_at` — **`category` yok**. `wardrobe_images` deposu anon anahtarla görünmüyor (yok ya da gizli).
- Sonuç ekranı dosyayı kök dizine `<uid>_<ts>.png` olarak yükleyip `getPublicUrl` kullanıyor (depo gizliyse görsel açılmaz).

## Hedefler
- **Tasarım (Claude'un kararı):** krem tema, ana ekranla aynı tipografi (Georgia başlık, koyu hap butonlar); üstte "Gardırobum" + kombin sayısı; **kategori filtresi** (Tümü / Üst / Alt / Tam) her birinde sayı; **2 sütunlu 3:4 kart ızgarası** (sonuç görseli 768×1024 olduğu için kırpılmaz), kartta kategori rozeti ve "x gün önce"; karta dokununca **detay ekranı**: büyük görsel (yakınlaştırılabilir), kategori/tarih, **Paylaş** ve **Sil** (onaylı).
- **Durumlar:** yükleniyor (iskelet kartlar), hata (tekrar dene), oturum yok ("Gardırobunu görmek için giriş yap" + giriş butonu), boş ("İlk kombinini dene" + ana ekrana dön), aşağı çekip yenileme.
- **Supabase:** kullanıcının kayıtlarını `created_at` azalan sırayla okuma; kaydetme kategoriyle; silme (satır + dosya).
- **Geriye uyum:** `category` sütunu yoksa kayıt sütunsuz tekrar denenir, okumada kategori yoksa "upper" varsayılır — kullanıcı SQL'i çalıştırmadan da uygulama çalışır.
- **SQL kurulum dosyası** (`supabase/setup_wardrobe.sql`): `category` sütunu, RLS (kullanıcı yalnızca kendi satırları), `wardrobe_images` deposu (public okuma, kullanıcı kendi klasörüne yazma/silme). Kullanıcı Supabase SQL Editor'da bir kez çalıştırır.
- Dosya yolu: `<uid>/<ts>.png` (depo kuralı klasörü kullanıcıyla eşler).

## Kapsam dışı
- Kombin adlandırma, favori, klasör/koleksiyon, karşılaştırma ekranı; denenen kıyafet görselinin ayrıca saklanması.

## Mimari
- `lib/models/wardrobe_item.dart`: `WardrobeItem(id, imageUrl, category, createdAt, storagePath)` + `fromRow`.
- `lib/services/wardrobe_repository.dart`: `abstract WardrobeRepository { fetch(); add(bytes, category); delete(item); }` + `SupabaseWardrobeRepository`. Ekranlar soyut tipe bağlı → testlerde sahte depo.
- `wardrobe_screen.dart` baştan yazılır; `wardrobe_detail_screen.dart` yeni.
- `result_screen.dart` kaydetmeyi depo üzerinden yapar.

## Test
`fromRow` (kategori var/yok, tarih), sütun-eksik hatası tanıma, ekran durumları (oturum yok / boş / liste / filtre / silme) sahte depoyla.
