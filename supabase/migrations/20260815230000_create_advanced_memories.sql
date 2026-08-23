-- Version 1.8: Advanced memories (themes, covers, captions, chapters, typed memories)

alter table public.memories
  add column if not exists memory_type text not null default 'prompt',
  add column if not exists caption text,
  add column if not exists theme text not null default 'minimal',
  add column if not exists cover_storage_path text,
  add column if not exists memory_date date;

alter table public.memories
  drop constraint if exists memories_memory_type_check;

alter table public.memories
  add constraint memories_memory_type_check check (
    memory_type in ('prompt', 'circle', 'anniversary', 'birthday', 'trip', 'custom')
  );

alter table public.memories
  drop constraint if exists memories_theme_check;

alter table public.memories
  add constraint memories_theme_check check (
    theme in (
      'minimal', 'glass', 'film', 'polaroid', 'midnight',
      'sunset', 'love', 'retro', 'memory'
    )
  );

alter table public.memories
  drop constraint if exists memories_caption_length_check;

alter table public.memories
  add constraint memories_caption_length_check check (
    caption is null or char_length(caption) <= 500
  );

create table if not exists public.memory_chapters (
  id uuid primary key default gen_random_uuid(),
  memory_id uuid not null references public.memories (id) on delete cascade,
  title text not null,
  caption text,
  position int not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  constraint memory_chapters_title_length check (char_length(title) between 1 and 80),
  constraint memory_chapters_caption_length check (
    caption is null or char_length(caption) <= 500
  )
);

create index if not exists memory_chapters_memory_position_idx
  on public.memory_chapters (memory_id, position);

alter table public.memory_items
  add column if not exists chapter_id uuid references public.memory_chapters (id) on delete set null;

alter table public.memory_chapters enable row level security;

drop policy if exists "Users can view memory chapters" on public.memory_chapters;
create policy "Users can view memory chapters"
on public.memory_chapters for select
to authenticated
using (
  exists (
    select 1 from public.memories m
    where m.id = memory_id
      and (
        m.owner_id = auth.uid()
        or exists (
          select 1 from public.memory_participants mp
          where mp.memory_id = m.id and mp.user_id = auth.uid()
        )
        or (
          m.circle_id is not null
          and exists (
            select 1 from public.circle_members cm
            where cm.circle_id = m.circle_id and cm.user_id = auth.uid()
          )
        )
      )
  )
);

drop policy if exists "Owners can manage memory chapters" on public.memory_chapters;
create policy "Owners can manage memory chapters"
on public.memory_chapters for all
to authenticated
using (
  exists (
    select 1 from public.memories m
    where m.id = memory_id and m.owner_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.memories m
    where m.id = memory_id and m.owner_id = auth.uid()
  )
);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'memory-covers',
  'memory-covers',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Memory covers readable by authenticated users" on storage.objects;
create policy "Memory covers readable by authenticated users"
on storage.objects for select
to authenticated
using (bucket_id = 'memory-covers');

drop policy if exists "Owners can upload memory covers" on storage.objects;
create policy "Owners can upload memory covers"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'memory-covers'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Owners can update memory covers" on storage.objects;
create policy "Owners can update memory covers"
on storage.objects for update
to authenticated
using (
  bucket_id = 'memory-covers'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'memory-covers'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Owners can delete memory covers" on storage.objects;
create policy "Owners can delete memory covers"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'memory-covers'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create or replace function public.get_memory_theme_catalog()
returns jsonb
language plpgsql
security definer
set search_path = public
stable
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  perform public.sync_moment_plus_entitlement(auth.uid());

  return jsonb_build_object(
    'themes',
    jsonb_build_array(
      'minimal', 'glass', 'film', 'polaroid', 'midnight',
      'sunset', 'love', 'retro', 'memory'
    ),
    'memory_types',
    jsonb_build_array(
      'prompt', 'circle', 'anniversary', 'birthday', 'trip', 'custom'
    ),
    'is_premium', public.has_moment_plus_entitlement(auth.uid())
  );
end;
$$;

create or replace function public.create_advanced_memory(
  p_title text,
  p_memory_type text,
  p_caption text default null,
  p_theme text default 'minimal',
  p_memory_date date default null,
  p_circle_id uuid default null
)
returns public.memories
language plpgsql
security definer
set search_path = public
as $$
declare
  new_memory public.memories;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if trim(p_title) = '' then
    raise exception 'Title is required';
  end if;

  if p_memory_type not in ('circle', 'anniversary', 'birthday', 'trip', 'custom') then
    raise exception 'Invalid memory type';
  end if;

  if p_theme not in (
    'minimal', 'glass', 'film', 'polaroid', 'midnight',
    'sunset', 'love', 'retro', 'memory'
  ) then
    raise exception 'Invalid theme';
  end if;

  if p_theme <> 'minimal' and not public.has_moment_plus_entitlement(auth.uid()) then
    raise exception 'Moment+ required for premium memory themes';
  end if;

  if p_memory_type = 'circle' and p_circle_id is null then
    raise exception 'Circle memories require a circle';
  end if;

  if p_circle_id is not null and not exists (
    select 1 from public.circle_members cm
    where cm.circle_id = p_circle_id and cm.user_id = auth.uid()
  ) then
    raise exception 'Not a circle member';
  end if;

  insert into public.memories (
    owner_id,
    title,
    memory_type,
    caption,
    theme,
    memory_date,
    circle_id
  )
  values (
    auth.uid(),
    trim(p_title),
    p_memory_type,
    nullif(trim(p_caption), ''),
    p_theme,
    p_memory_date,
    p_circle_id
  )
  returning * into new_memory;

  if p_circle_id is not null then
    insert into public.memory_participants (memory_id, user_id)
    select new_memory.id, cm.user_id
    from public.circle_members cm
    where cm.circle_id = p_circle_id
    on conflict do nothing;
  end if;

  return new_memory;
end;
$$;

create or replace function public.update_memory_advanced(
  p_memory_id uuid,
  p_title text,
  p_caption text default null,
  p_theme text default 'minimal',
  p_memory_date date default null,
  p_cover_moment_id uuid default null,
  p_cover_storage_path text default null
)
returns public.memories
language plpgsql
security definer
set search_path = public
as $$
declare
  updated public.memories;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1 from public.memories m
    where m.id = p_memory_id and m.owner_id = auth.uid()
  ) then
    raise exception 'Not memory owner';
  end if;

  if trim(p_title) = '' then
    raise exception 'Title is required';
  end if;

  if p_theme not in (
    'minimal', 'glass', 'film', 'polaroid', 'midnight',
    'sunset', 'love', 'retro', 'memory'
  ) then
    raise exception 'Invalid theme';
  end if;

  if p_theme <> 'minimal' and not public.has_moment_plus_entitlement(auth.uid()) then
    raise exception 'Moment+ required for premium memory themes';
  end if;

  if p_cover_moment_id is not null and not exists (
    select 1
    from public.memory_items mi
    where mi.memory_id = p_memory_id and mi.moment_id = p_cover_moment_id
  ) then
    raise exception 'Cover moment must belong to this memory';
  end if;

  update public.memories
  set
    title = trim(p_title),
    caption = nullif(trim(p_caption), ''),
    theme = p_theme,
    memory_date = p_memory_date,
    cover_moment_id = p_cover_moment_id,
    cover_storage_path = p_cover_storage_path
  where id = p_memory_id
  returning * into updated;

  return updated;
end;
$$;

create or replace function public.upsert_memory_chapter(
  p_memory_id uuid,
  p_title text,
  p_chapter_id uuid default null,
  p_caption text default null,
  p_position int default 0,
  p_starts_at timestamptz default null,
  p_ends_at timestamptz default null
)
returns public.memory_chapters
language plpgsql
security definer
set search_path = public
as $$
declare
  chapter public.memory_chapters;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1 from public.memories m
    where m.id = p_memory_id and m.owner_id = auth.uid()
  ) then
    raise exception 'Not memory owner';
  end if;

  if trim(p_title) = '' then
    raise exception 'Chapter title is required';
  end if;

  if p_chapter_id is null then
    insert into public.memory_chapters (
      memory_id, title, caption, position, starts_at, ends_at
    )
    values (
      p_memory_id,
      trim(p_title),
      nullif(trim(p_caption), ''),
      p_position,
      p_starts_at,
      p_ends_at
    )
    returning * into chapter;
  else
    update public.memory_chapters
    set
      title = trim(p_title),
      caption = nullif(trim(p_caption), ''),
      position = p_position,
      starts_at = p_starts_at,
      ends_at = p_ends_at
    where id = p_chapter_id and memory_id = p_memory_id
    returning * into chapter;

    if not found then
      raise exception 'Chapter not found';
    end if;
  end if;

  return chapter;
end;
$$;

create or replace function public.delete_memory_chapter(p_chapter_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1
    from public.memory_chapters mc
    join public.memories m on m.id = mc.memory_id
    where mc.id = p_chapter_id and m.owner_id = auth.uid()
  ) then
    raise exception 'Not memory owner';
  end if;

  update public.memory_items
  set chapter_id = null
  where chapter_id = p_chapter_id;

  delete from public.memory_chapters
  where id = p_chapter_id;
end;
$$;

create or replace function public.create_memory_from_prompt_responses(
  p_title text,
  p_circle_id uuid,
  p_prompt_id uuid
)
returns public.memories
language plpgsql
security definer
set search_path = public
as $$
declare
  new_memory public.memories;
  response_count int;
  min_at timestamptz;
  max_at timestamptz;
  first_moment_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1 from public.circle_members cm
    where cm.circle_id = p_circle_id and cm.user_id = auth.uid()
  ) then
    raise exception 'Not a circle member';
  end if;

  select count(*) into response_count
  from public.prompt_responses pr
  where pr.circle_id = p_circle_id and pr.prompt_id = p_prompt_id;

  if response_count = 0 then
    raise exception 'No prompt responses to save';
  end if;

  select min(m.created_at), max(m.created_at)
  into min_at, max_at
  from public.prompt_responses pr
  join public.moments m on m.id = pr.moment_id
  where pr.circle_id = p_circle_id and pr.prompt_id = p_prompt_id;

  select pr.moment_id into first_moment_id
  from public.prompt_responses pr
  where pr.circle_id = p_circle_id and pr.prompt_id = p_prompt_id
  order by pr.created_at
  limit 1;

  insert into public.memories (
    owner_id,
    title,
    cover_moment_id,
    circle_id,
    prompt_id,
    starts_at,
    ends_at,
    memory_type,
    memory_date
  )
  values (
    auth.uid(),
    trim(p_title),
    first_moment_id,
    p_circle_id,
    p_prompt_id,
    min_at,
    max_at,
    'prompt',
    min_at::date
  )
  returning * into new_memory;

  insert into public.memory_items (memory_id, moment_id, position)
  select
    new_memory.id,
    pr.moment_id,
    row_number() over (order by pr.created_at) - 1
  from public.prompt_responses pr
  where pr.circle_id = p_circle_id and pr.prompt_id = p_prompt_id;

  insert into public.memory_participants (memory_id, user_id)
  select new_memory.id, cm.user_id
  from public.circle_members cm
  where cm.circle_id = p_circle_id
  on conflict do nothing;

  return new_memory;
end;
$$;

revoke all on function public.get_memory_theme_catalog() from public;
revoke all on function public.create_advanced_memory(text, text, text, text, date, uuid) from public;
revoke all on function public.update_memory_advanced(uuid, text, text, text, date, uuid, text) from public;
revoke all on function public.upsert_memory_chapter(uuid, text, uuid, text, int, timestamptz, timestamptz) from public;
revoke all on function public.delete_memory_chapter(uuid) from public;
revoke all on function public.get_memory_theme_catalog() from anon;
revoke all on function public.create_advanced_memory(text, text, text, text, date, uuid) from anon;
revoke all on function public.update_memory_advanced(uuid, text, text, text, date, uuid, text) from anon;
revoke all on function public.upsert_memory_chapter(uuid, text, uuid, text, int, timestamptz, timestamptz) from anon;
revoke all on function public.delete_memory_chapter(uuid) from anon;
grant execute on function public.get_memory_theme_catalog() to authenticated;
grant execute on function public.create_advanced_memory(text, text, text, text, date, uuid) to authenticated;
grant execute on function public.update_memory_advanced(uuid, text, text, text, date, uuid, text) to authenticated;
grant execute on function public.upsert_memory_chapter(uuid, text, uuid, text, int, timestamptz, timestamptz) to authenticated;
grant execute on function public.delete_memory_chapter(uuid) to authenticated;
