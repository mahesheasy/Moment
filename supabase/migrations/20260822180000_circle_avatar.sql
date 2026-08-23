-- Custom circle profile photos (Moment+), stored in circle-avatars bucket.

alter table public.circles
  add column if not exists avatar_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'circle-avatars',
  'circle-avatars',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Circle avatars readable by authenticated users" on storage.objects;
create policy "Circle avatars readable by authenticated users"
on storage.objects for select
to authenticated
using (bucket_id = 'circle-avatars');

drop policy if exists "Circle owners can upload circle avatar" on storage.objects;
create policy "Circle owners can upload circle avatar"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'circle-avatars'
  and exists (
    select 1 from public.circles c
    where c.owner_id = auth.uid()
      and (storage.foldername(name))[1] = c.id::text
  )
);

drop policy if exists "Circle owners can update circle avatar" on storage.objects;
create policy "Circle owners can update circle avatar"
on storage.objects for update
to authenticated
using (
  bucket_id = 'circle-avatars'
  and exists (
    select 1 from public.circles c
    where c.owner_id = auth.uid()
      and (storage.foldername(name))[1] = c.id::text
  )
)
with check (
  bucket_id = 'circle-avatars'
  and exists (
    select 1 from public.circles c
    where c.owner_id = auth.uid()
      and (storage.foldername(name))[1] = c.id::text
  )
);

drop policy if exists "Circle owners can delete circle avatar" on storage.objects;
create policy "Circle owners can delete circle avatar"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'circle-avatars'
  and exists (
    select 1 from public.circles c
    where c.owner_id = auth.uid()
      and (storage.foldername(name))[1] = c.id::text
  )
);
