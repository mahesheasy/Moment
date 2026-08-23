-- Version 1.4: memory vault

create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  cover_moment_id uuid references public.moments (id) on delete set null,
  circle_id uuid references public.circles (id) on delete set null,
  prompt_id uuid references public.daily_prompts (id) on delete set null,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  constraint memories_title_length check (char_length(title) between 1 and 60)
);

create unique index if not exists memories_owner_prompt_circle_uidx
  on public.memories (owner_id, prompt_id, circle_id)
  where prompt_id is not null and circle_id is not null;

create table if not exists public.memory_items (
  memory_id uuid not null references public.memories (id) on delete cascade,
  moment_id uuid not null references public.moments (id) on delete cascade,
  position int not null default 0,
  added_at timestamptz not null default timezone('utc', now()),
  primary key (memory_id, moment_id)
);

create index if not exists memory_items_memory_position_idx
  on public.memory_items (memory_id, position);

create table if not exists public.memory_participants (
  memory_id uuid not null references public.memories (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default timezone('utc', now()),
  primary key (memory_id, user_id)
);

alter table public.memories enable row level security;
alter table public.memory_items enable row level security;
alter table public.memory_participants enable row level security;

drop policy if exists "Users can view accessible memories" on public.memories;
create policy "Users can view accessible memories"
on public.memories for select
to authenticated
using (
  auth.uid() = owner_id
  or exists (
    select 1 from public.memory_participants mp
    where mp.memory_id = id and mp.user_id = auth.uid()
  )
  or (
    circle_id is not null
    and exists (
      select 1 from public.circle_members cm
      where cm.circle_id = memories.circle_id and cm.user_id = auth.uid()
    )
  )
);

drop policy if exists "Users can create memories" on public.memories;
create policy "Users can create memories"
on public.memories for insert
to authenticated
with check (auth.uid() = owner_id);

drop policy if exists "Owners can update memories" on public.memories;
create policy "Owners can update memories"
on public.memories for update
to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "Owners can delete memories" on public.memories;
create policy "Owners can delete memories"
on public.memories for delete
to authenticated
using (auth.uid() = owner_id);

drop policy if exists "Users can view memory items" on public.memory_items;
create policy "Users can view memory items"
on public.memory_items for select
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

drop policy if exists "Owners can add memory items" on public.memory_items;
create policy "Owners can add memory items"
on public.memory_items for insert
to authenticated
with check (
  exists (
    select 1 from public.memories m
    where m.id = memory_id and m.owner_id = auth.uid()
  )
);

drop policy if exists "Owners can remove memory items" on public.memory_items;
create policy "Owners can remove memory items"
on public.memory_items for delete
to authenticated
using (
  exists (
    select 1 from public.memories m
    where m.id = memory_id and m.owner_id = auth.uid()
  )
);

drop policy if exists "Users can view memory participants" on public.memory_participants;
create policy "Users can view memory participants"
on public.memory_participants for select
to authenticated
using (
  exists (
    select 1 from public.memories m
    where m.id = memory_id
      and (
        m.owner_id = auth.uid()
        or user_id = auth.uid()
        or exists (
          select 1 from public.memory_participants mp
          where mp.memory_id = m.id and mp.user_id = auth.uid()
        )
      )
  )
);

drop policy if exists "Owners can manage memory participants" on public.memory_participants;
create policy "Owners can manage memory participants"
on public.memory_participants for insert
to authenticated
with check (
  exists (
    select 1 from public.memories m
    where m.id = memory_id and m.owner_id = auth.uid()
  )
);

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
    ends_at
  )
  values (
    auth.uid(),
    trim(p_title),
    first_moment_id,
    p_circle_id,
    p_prompt_id,
    min_at,
    max_at
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

revoke all on function public.create_memory_from_prompt_responses(text, uuid, uuid) from public;
revoke all on function public.create_memory_from_prompt_responses(text, uuid, uuid) from anon;
grant execute on function public.create_memory_from_prompt_responses(text, uuid, uuid) to authenticated;
