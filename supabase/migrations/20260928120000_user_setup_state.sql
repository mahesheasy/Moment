-- Widget reminder metadata (friend state lives in friendships).

create table if not exists public.user_setup_state (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  widget_reminder_last_shown_at timestamptz,
  widget_reminder_dismissed_count integer not null default 0,
  widget_setup_confirmed boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint user_setup_state_user_id_unique unique (user_id),
  constraint user_setup_state_dismissed_count_nonneg check (
    widget_reminder_dismissed_count >= 0
  )
);

create index if not exists user_setup_state_user_id_idx
  on public.user_setup_state (user_id);

alter table public.user_setup_state enable row level security;

drop policy if exists "Users read own setup state" on public.user_setup_state;
create policy "Users read own setup state"
  on public.user_setup_state
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Users insert own setup state" on public.user_setup_state;
create policy "Users insert own setup state"
  on public.user_setup_state
  for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Users update own setup state" on public.user_setup_state;
create policy "Users update own setup state"
  on public.user_setup_state
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
