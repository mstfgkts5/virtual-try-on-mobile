-- SeeItOn gardırop kurulumu (Supabase Dashboard → SQL Editor → New query → yapıştır → Run)
-- Birden fazla kez çalıştırmak güvenlidir.
--
-- Ne yapar:
--   1. wardrobe tablosuna kategori sütunu ekler (üst / alt / tam kıyafet)
--   2. Satır düzeyi güvenlik: her kullanıcı yalnızca kendi kombinlerini görür, ekler, siler
--   3. wardrobe_images görsel deposunu oluşturur (herkese açık okuma, görsel adresleriyle açılabilsin)
--   4. Depo kuralları: kullanıcı yalnızca kendi klasörüne (<kullanıcı-id>/...) yükleyip silebilir

-- 1) Kategori sütunu -----------------------------------------------------------
alter table public.wardrobe
  add column if not exists category text not null default 'upper';

alter table public.wardrobe drop constraint if exists wardrobe_category_check;
alter table public.wardrobe
  add constraint wardrobe_category_check check (category in ('upper', 'lower', 'overall'));

alter table public.wardrobe alter column created_at set default now();

-- 2) Satır düzeyi güvenlik (RLS) ------------------------------------------------
-- user_id uuid ya da text olabilir; ikisinde de çalışsın diye metin olarak karşılaştırılır
alter table public.wardrobe enable row level security;

drop policy if exists "wardrobe_select_own" on public.wardrobe;
create policy "wardrobe_select_own" on public.wardrobe
  for select to authenticated using (user_id::text = auth.uid()::text);

drop policy if exists "wardrobe_insert_own" on public.wardrobe;
create policy "wardrobe_insert_own" on public.wardrobe
  for insert to authenticated with check (user_id::text = auth.uid()::text);

drop policy if exists "wardrobe_delete_own" on public.wardrobe;
create policy "wardrobe_delete_own" on public.wardrobe
  for delete to authenticated using (user_id::text = auth.uid()::text);

-- 3) Görsel deposu ---------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('wardrobe_images', 'wardrobe_images', true)
on conflict (id) do update set public = true;

-- 4) Depo kuralları: yol "<kullanıcı-id>/<zaman>.png" ---------------------------
drop policy if exists "wardrobe_images_insert_own" on storage.objects;
create policy "wardrobe_images_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'wardrobe_images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "wardrobe_images_delete_own" on storage.objects;
create policy "wardrobe_images_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'wardrobe_images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "wardrobe_images_read" on storage.objects;
create policy "wardrobe_images_read" on storage.objects
  for select using (bucket_id = 'wardrobe_images');
