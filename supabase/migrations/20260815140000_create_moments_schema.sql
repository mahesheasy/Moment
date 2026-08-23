-- Version 0.5/0.6: moments, recipients, private storage

create table if not exists public.moments (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles (id) on delete cascade,
  storage_path text not null,
  thumbnail_path text,
  caption text,
  idempotency_key text,
  created_at timestamptz not null default timezone('utc', now()),
  constraint moments_caption_length check (caption is null or char_length(caption) <= 280)
);

create unique index if not exists moments_sender_idempotency_key
  on public.moments (sender_id, idempotency_key)
  where idempotency_key is not null;

create table if not exists public.moment_recipients (
  moment_id uuid not null references public.moments (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  delivery_status text not null default 'pending',
  seen_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (moment_id, recipient_id),
  constraint moment_recipients_status_check check (
    delivery_status in ('pending', 'delivered', 'failed')
  )
);

create index if not exists moment_recipients_recipient_created_idx
  on public.moment_recipients (recipient_id, created_at desc);

alter table public.moments enable row level security;
alter table public.moment_recipients enable row level security;

drop policy if exists "Senders can insert moments" on public.moments;
create policy "Senders can insert moments"
on public.moments for insert
to authenticated
with check (auth.uid() = sender_id);

drop policy if exists "Users can view sent or received moments" on public.moments;
create policy "Users can view sent or received moments"
on public.moments for select
to authenticated
using (
  auth.uid() = sender_id
  or exists (
    select 1 from public.moment_recipients mr
    where mr.moment_id = id and mr.recipient_id = auth.uid()
  )
);

drop policy if exists "Senders can insert recipients" on public.moment_recipients;
create policy "Senders can insert recipients"
on public.moment_recipients for insert
to authenticated
with check (
  exists (
    select 1 from public.moments m
    where m.id = moment_id and m.sender_id = auth.uid()
  )
);

drop policy if exists "Recipients can view own delivery rows" on public.moment_recipients;
create policy "Recipients can view own delivery rows"
on public.moment_recipients for select
to authenticated
using (
  auth.uid() = recipient_id
  or exists (
    select 1 from public.moments m
    where m.id = moment_id and m.sender_id = auth.uid()
  )
);

drop policy if exists "Recipients can mark moments seen" on public.moment_recipients;
create policy "Recipients can mark moments seen"
on public.moment_recipients for update
to authenticated
using (auth.uid() = recipient_id)
with check (auth.uid() = recipient_id);

drop policy if exists "Senders can update delivery status" on public.moment_recipients;
create policy "Senders can update delivery status"
on public.moment_recipients for update
to authenticated
using (
  exists (
    select 1 from public.moments m
    where m.id = moment_id and m.sender_id = auth.uid()
  )
);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'moments',
  'moments',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users can upload own moments" on storage.objects;
create policy "Users can upload own moments"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'moments'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can read accessible moments" on storage.objects;
create policy "Users can read accessible moments"
on storage.objects for select
to authenticated
using (
  bucket_id = 'moments'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or exists (
      select 1
      from public.moments m
      join public.moment_recipients mr on mr.moment_id = m.id
      where mr.recipient_id = auth.uid()
        and m.storage_path = name
    )
  )
);
