-- Version 1.2: circles + members

create table if not exists public.circles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  circle_type text not null default 'custom',
  emoji text,
  created_at timestamptz not null default timezone('utc', now()),
  constraint circles_name_length check (char_length(name) between 1 and 40),
  constraint circles_type_check check (
    circle_type in ('us', 'squad', 'family', 'college', 'custom')
  )
);

create table if not exists public.circle_members (
  circle_id uuid not null references public.circles (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member',
  joined_at timestamptz not null default timezone('utc', now()),
  primary key (circle_id, user_id),
  constraint circle_members_role_check check (role in ('owner', 'member'))
);

create index if not exists circle_members_user_id_idx on public.circle_members (user_id);

alter table public.circles enable row level security;
alter table public.circle_members enable row level security;

drop policy if exists "Members can view circles" on public.circles;
create policy "Members can view circles"
on public.circles for select
to authenticated
using (
  exists (
    select 1 from public.circle_members cm
    where cm.circle_id = id and cm.user_id = auth.uid()
  )
);

drop policy if exists "Users can create circles" on public.circles;
create policy "Users can create circles"
on public.circles for insert
to authenticated
with check (auth.uid() = owner_id);

drop policy if exists "Owners can update circles" on public.circles;
create policy "Owners can update circles"
on public.circles for update
to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "Owners can delete circles" on public.circles;
create policy "Owners can delete circles"
on public.circles for delete
to authenticated
using (auth.uid() = owner_id);

drop policy if exists "Members can view circle membership" on public.circle_members;
create policy "Members can view circle membership"
on public.circle_members for select
to authenticated
using (
  exists (
    select 1 from public.circle_members mine
    where mine.circle_id = circle_id and mine.user_id = auth.uid()
  )
);

drop policy if exists "Owners can add circle members" on public.circle_members;
create policy "Owners can add circle members"
on public.circle_members for insert
to authenticated
with check (
  exists (
    select 1 from public.circles c
    where c.id = circle_id and c.owner_id = auth.uid()
  )
  or (
    auth.uid() = user_id
    and role = 'owner'
    and exists (
      select 1 from public.circles c
      where c.id = circle_id and c.owner_id = auth.uid()
    )
  )
);

drop policy if exists "Owners can remove circle members" on public.circle_members;
create policy "Owners can remove circle members"
on public.circle_members for delete
to authenticated
using (
  exists (
    select 1 from public.circles c
    where c.id = circle_id and c.owner_id = auth.uid()
  )
  or auth.uid() = user_id
);

create or replace function public.create_circle_with_owner(
  p_name text,
  p_circle_type text,
  p_emoji text default null
)
returns public.circles
language plpgsql
security definer
set search_path = public
as $$
declare
  new_circle public.circles;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.circles (owner_id, name, circle_type, emoji)
  values (auth.uid(), p_name, p_circle_type, p_emoji)
  returning * into new_circle;

  insert into public.circle_members (circle_id, user_id, role)
  values (new_circle.id, auth.uid(), 'owner');

  return new_circle;
end;
$$;

revoke all on function public.create_circle_with_owner(text, text, text) from public;
revoke all on function public.create_circle_with_owner(text, text, text) from anon;
grant execute on function public.create_circle_with_owner(text, text, text) to authenticated;
