-- Version 1.3: daily prompts + circle responses

create table if not exists public.daily_prompts (
  id uuid primary key default gen_random_uuid(),
  prompt_date date not null unique,
  prompt_text text not null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint daily_prompts_text_length check (char_length(prompt_text) between 3 and 200)
);

create table if not exists public.prompt_responses (
  id uuid primary key default gen_random_uuid(),
  prompt_id uuid not null references public.daily_prompts (id) on delete cascade,
  circle_id uuid not null references public.circles (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  moment_id uuid not null references public.moments (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  constraint prompt_responses_unique_user unique (prompt_id, circle_id, user_id)
);

create index if not exists prompt_responses_circle_prompt_idx
  on public.prompt_responses (circle_id, prompt_id, created_at desc);

alter table public.daily_prompts enable row level security;
alter table public.prompt_responses enable row level security;

drop policy if exists "Authenticated users can view daily prompts" on public.daily_prompts;
create policy "Authenticated users can view daily prompts"
on public.daily_prompts for select
to authenticated
using (true);

drop policy if exists "Circle members can view prompt responses" on public.prompt_responses;
create policy "Circle members can view prompt responses"
on public.prompt_responses for select
to authenticated
using (
  exists (
    select 1 from public.circle_members cm
    where cm.circle_id = prompt_responses.circle_id
      and cm.user_id = auth.uid()
  )
);

drop policy if exists "Members can submit prompt responses" on public.prompt_responses;
create policy "Members can submit prompt responses"
on public.prompt_responses for insert
to authenticated
with check (
  auth.uid() = user_id
  and exists (
    select 1 from public.circle_members cm
    where cm.circle_id = circle_id and cm.user_id = auth.uid()
  )
  and exists (
    select 1 from public.moments m
    where m.id = moment_id and m.sender_id = auth.uid()
  )
);

create or replace function public.get_todays_prompt()
returns public.daily_prompts
language plpgsql
security definer
set search_path = public
as $$
declare
  today date := (timezone('utc', now()))::date;
  result public.daily_prompts;
  templates text[] := array[
    'Show us what made you smile today.',
    'What are you looking at right now?',
    'Show us your current view.',
    'What did you eat today?',
    'What''s one good thing that happened?',
    'Capture something that feels like home.',
    'What color is dominating your day?',
    'Show us a tiny detail you noticed.',
    'What made you laugh today?',
    'Share a moment of calm.',
    'What are you grateful for right now?',
    'Show us your favorite corner today.',
    'What did today taste like?',
    'Capture something beautiful nearby.',
    'What would you like to remember from today?'
  ];
  template_index int;
begin
  select * into result from public.daily_prompts where prompt_date = today;
  if found then
    return result;
  end if;

  template_index := (extract(doy from today)::int % array_length(templates, 1)) + 1;

  insert into public.daily_prompts (prompt_date, prompt_text)
  values (today, templates[template_index])
  returning * into result;

  return result;
end;
$$;

revoke all on function public.get_todays_prompt() from public;
revoke all on function public.get_todays_prompt() from anon;
grant execute on function public.get_todays_prompt() to authenticated;
