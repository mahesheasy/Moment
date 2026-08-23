-- Version 1.1: moment reactions + pings

create table if not exists public.moment_reactions (
  moment_id uuid not null references public.moments (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  reaction text not null,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (moment_id, user_id),
  constraint moment_reactions_type_check check (
    reaction in ('heart', 'laugh', 'fire', 'love', 'wow')
  )
);

create table if not exists public.pings (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  moment_id uuid references public.moments (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint pings_no_self check (sender_id != recipient_id)
);

create index if not exists pings_recipient_created_idx
  on public.pings (recipient_id, created_at desc);

alter table public.moment_reactions enable row level security;
alter table public.pings enable row level security;

drop policy if exists "Users can view reactions on accessible moments" on public.moment_reactions;
create policy "Users can view reactions on accessible moments"
on public.moment_reactions for select
to authenticated
using (
  exists (
    select 1 from public.moments m
    where m.id = moment_id
      and (
        m.sender_id = auth.uid()
        or exists (
          select 1 from public.moment_recipients mr
          where mr.moment_id = m.id and mr.recipient_id = auth.uid()
        )
      )
  )
);

drop policy if exists "Users can react to accessible moments" on public.moment_reactions;
create policy "Users can react to accessible moments"
on public.moment_reactions for insert
to authenticated
with check (
  auth.uid() = user_id
  and exists (
    select 1 from public.moments m
    where m.id = moment_id
      and (
        m.sender_id = auth.uid()
        or exists (
          select 1 from public.moment_recipients mr
          where mr.moment_id = m.id and mr.recipient_id = auth.uid()
        )
      )
  )
);

drop policy if exists "Users can update own reactions" on public.moment_reactions;
create policy "Users can update own reactions"
on public.moment_reactions for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can remove own reactions" on public.moment_reactions;
create policy "Users can remove own reactions"
on public.moment_reactions for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can send pings" on public.pings;
create policy "Users can send pings"
on public.pings for insert
to authenticated
with check (auth.uid() = sender_id);

drop policy if exists "Users can view sent or received pings" on public.pings;
create policy "Users can view sent or received pings"
on public.pings for select
to authenticated
using (auth.uid() = sender_id or auth.uid() = recipient_id);

alter publication supabase_realtime add table public.moment_reactions;
alter publication supabase_realtime add table public.pings;
