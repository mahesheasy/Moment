create table if not exists public.support_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  category text not null,
  description text not null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint support_reports_category_length check (char_length(category) between 3 and 80),
  constraint support_reports_description_length check (char_length(description) between 10 and 2000)
);

create index if not exists support_reports_user_id_idx on public.support_reports (user_id);

alter table public.support_reports enable row level security;

drop policy if exists "Users can submit support reports" on public.support_reports;
create policy "Users can submit support reports"
on public.support_reports for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can view own support reports" on public.support_reports;
create policy "Users can view own support reports"
on public.support_reports for select
to authenticated
using (auth.uid() = user_id);
