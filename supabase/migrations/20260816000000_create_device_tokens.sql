-- Version 1.9: FCM device tokens for push-driven widget updates

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  token text not null unique,
  platform text not null default 'android',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint device_tokens_platform_check check (platform in ('android', 'ios'))
);

create index if not exists device_tokens_user_idx
  on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

drop policy if exists "Users can view own device tokens" on public.device_tokens;
create policy "Users can view own device tokens"
on public.device_tokens for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can delete own device tokens" on public.device_tokens;
create policy "Users can delete own device tokens"
on public.device_tokens for delete
to authenticated
using (auth.uid() = user_id);

-- Registration goes through the RPC so a token that moves between accounts is
-- reassigned rather than duplicated (same physical device, different login).
create or replace function public.register_device_token(
  p_token text,
  p_platform text default 'android'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if p_token is null or length(trim(p_token)) = 0 then
    raise exception 'Token required';
  end if;

  if p_platform not in ('android', 'ios') then
    raise exception 'Invalid platform';
  end if;

  insert into public.device_tokens (user_id, token, platform)
  values (auth.uid(), trim(p_token), p_platform)
  on conflict (token) do update set
    user_id = excluded.user_id,
    platform = excluded.platform,
    updated_at = timezone('utc', now());
end;
$$;

create or replace function public.remove_device_token(p_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  delete from public.device_tokens
  where token = trim(p_token)
    and user_id = auth.uid();
end;
$$;

revoke all on function public.register_device_token(text, text) from public;
revoke all on function public.register_device_token(text, text) from anon;
revoke all on function public.remove_device_token(text) from public;
revoke all on function public.remove_device_token(text) from anon;
grant execute on function public.register_device_token(text, text) to authenticated;
grant execute on function public.remove_device_token(text) to authenticated;
