-- SeeItOn · Gizlilik (KVKK) kurulumu — setup_wardrobe.sql'den SONRA bir kez çalıştırılır.
-- Supabase → SQL Editor → New query → bu dosyanın içeriği → Run
--
-- 1) wardrobe_images deposunu özel yapar: görseller artık herkese açık URL ile açılmaz;
--    uygulama her görsel için 1 saat geçerli imzalı URL ister (SupabaseWardrobeRepository.fetch).
-- 2) Kullanıcının kendi hesabını silebilmesi için delete_user() fonksiyonunu ekler
--    (Ayarlar → "Hesabımı ve verilerimi sil").

-- 1) Depo özel
update storage.buckets set public = false where id = 'wardrobe_images';

-- İmzalı URL üretmek ve klasörü listelemek için okuma kuralı yalnızca kendi klasörüne izin verir
-- (setup_wardrobe.sql ile aynı kural; burada yeniden kurularak bu dosya tek başına da tutarlı olur)
drop policy if exists "wardrobe_images_read" on storage.objects;
drop policy if exists "wardrobe_images_select_own" on storage.objects;
create policy "wardrobe_images_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'wardrobe_images' and (storage.foldername(name))[1] = auth.uid()::text);

-- 2) Hesap silme: yalnızca çağıran kullanıcının kendi kaydını siler.
--    security definer: auth.users tablosuna normal kullanıcı yazamaz; fonksiyon sahibinin yetkisiyle çalışır.
--    Görseller ve wardrobe satırları uygulama tarafından bu çağrıdan önce silinir;
--    yine de kalan satırlar varsa burada temizlenir.
create or replace function public.delete_user()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not signed in';
  end if;
  delete from public.wardrobe where user_id::text = uid::text;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_user() from public, anon;
grant execute on function public.delete_user() to authenticated;
