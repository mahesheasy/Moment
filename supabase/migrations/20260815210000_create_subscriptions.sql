-- Version 1.6: Moment+ subscription shell + remote plan config

create table if not exists public.subscription_plans (
  id text primary key,
  display_name text not null,
  price_cents integer not null,
  currency text not null default 'INR',
  billing_interval text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  constraint subscription_plans_interval_check check (
    billing_interval in ('month', 'year')
  ),
  constraint subscription_plans_price_check check (price_cents > 0)
);

create table if not exists public.app_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles (id) on delete cascade,
  plan_id text not null references public.subscription_plans (id),
  status text not null default 'active',
  started_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz,
  cancelled_at timestamptz,
  provider text not null default 'manual',
  provider_ref text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint subscriptions_status_check check (
    status in ('active', 'cancelled', 'expired', 'trialing', 'pending')
  )
);

create table if not exists public.subscription_entitlements (
  user_id uuid not null references public.profiles (id) on delete cascade,
  entitlement_key text not null,
  granted_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz,
  primary key (user_id, entitlement_key)
);

insert into public.subscription_plans (id, display_name, price_cents, currency, billing_interval, sort_order)
values
  ('monthly', 'Monthly', 9900, 'INR', 'month', 1),
  ('yearly', 'Yearly', 69900, 'INR', 'year', 2)
on conflict (id) do update set
  display_name = excluded.display_name,
  price_cents = excluded.price_cents,
  currency = excluded.currency,
  billing_interval = excluded.billing_interval,
  sort_order = excluded.sort_order;

insert into public.app_config (key, value)
values
  ('moment_plus', jsonb_build_object(
    'free_memory_limit', 3,
    'premium_entitlement', 'moment_plus'
  ))
on conflict (key) do update set value = excluded.value;

alter table public.subscription_plans enable row level security;
alter table public.app_config enable row level security;
alter table public.subscriptions enable row level security;
alter table public.subscription_entitlements enable row level security;

drop policy if exists "Authenticated users can view active plans" on public.subscription_plans;
create policy "Authenticated users can view active plans"
on public.subscription_plans for select
to authenticated
using (is_active = true);

drop policy if exists "Authenticated users can view app config" on public.app_config;
create policy "Authenticated users can view app config"
on public.app_config for select
to authenticated
using (true);

drop policy if exists "Users can view own subscription" on public.subscriptions;
create policy "Users can view own subscription"
on public.subscriptions for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can view own entitlements" on public.subscription_entitlements;
create policy "Users can view own entitlements"
on public.subscription_entitlements for select
to authenticated
using (auth.uid() = user_id);

create or replace function public.sync_moment_plus_entitlement(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  sub public.subscriptions;
begin
  select * into sub
  from public.subscriptions
  where user_id = p_user_id
    and status in ('active', 'trialing')
    and (expires_at is null or expires_at > timezone('utc', now()))
  limit 1;

  if found then
    insert into public.subscription_entitlements (user_id, entitlement_key, expires_at)
    values (p_user_id, 'moment_plus', sub.expires_at)
    on conflict (user_id, entitlement_key) do update
      set expires_at = excluded.expires_at,
          granted_at = timezone('utc', now());
  else
    delete from public.subscription_entitlements
    where user_id = p_user_id and entitlement_key = 'moment_plus';
  end if;
end;
$$;

create or replace function public.get_moment_plus_offering()
returns jsonb
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  result jsonb;
  memory_count integer := 0;
  free_limit integer := 3;
  config jsonb;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  perform public.sync_moment_plus_entitlement(auth.uid());

  select value into config from public.app_config where key = 'moment_plus';
  if config ? 'free_memory_limit' then
    free_limit := (config ->> 'free_memory_limit')::integer;
  end if;

  select count(*) into memory_count
  from public.memories
  where owner_id = auth.uid();

  select jsonb_build_object(
    'plans',
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', sp.id,
            'display_name', sp.display_name,
            'price_cents', sp.price_cents,
            'currency', sp.currency,
            'billing_interval', sp.billing_interval
          )
          order by sp.sort_order
        )
        from public.subscription_plans sp
        where sp.is_active = true
      ),
      '[]'::jsonb
    ),
    'subscription',
    (
      select jsonb_build_object(
        'plan_id', s.plan_id,
        'status', s.status,
        'expires_at', s.expires_at
      )
      from public.subscriptions s
      where s.user_id = auth.uid()
      limit 1
    ),
    'entitlements',
    coalesce(
      (
        select jsonb_agg(se.entitlement_key)
        from public.subscription_entitlements se
        where se.user_id = auth.uid()
          and (se.expires_at is null or se.expires_at > timezone('utc', now()))
      ),
      '[]'::jsonb
    ),
    'limits',
    jsonb_build_object(
      'free_memory_limit', free_limit,
      'memory_count', memory_count
    ),
    'features',
    jsonb_build_array(
      'Premium widgets',
      'Premium themes',
      'Unlimited memories',
      'Time Travel+',
      'HD archive',
      'Advanced circles',
      'Custom prompts',
      'Premium memory themes'
    )
  ) into result;

  return result;
end;
$$;

create or replace function public.request_moment_plus_checkout(p_plan_id text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1 from public.subscription_plans
    where id = p_plan_id and is_active = true
  ) then
    raise exception 'Invalid plan';
  end if;

  return jsonb_build_object(
    'status', 'pending',
    'message', 'Checkout will connect to App Store / Play Billing in a future update.',
    'plan_id', p_plan_id
  );
end;
$$;

revoke all on function public.sync_moment_plus_entitlement(uuid) from public;
revoke all on function public.get_moment_plus_offering() from public;
revoke all on function public.request_moment_plus_checkout(text) from public;
revoke all on function public.sync_moment_plus_entitlement(uuid) from anon;
revoke all on function public.get_moment_plus_offering() from anon;
revoke all on function public.request_moment_plus_checkout(text) from anon;
grant execute on function public.sync_moment_plus_entitlement(uuid) to authenticated;
grant execute on function public.get_moment_plus_offering() to authenticated;
grant execute on function public.request_moment_plus_checkout(text) to authenticated;
