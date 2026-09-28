-- Shared 3D Pet: connections, pets, actions, RLS, server-side actions

create table if not exists public.friend_connections (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles (id) on delete cascade,
  user_b uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  constraint friend_connections_ordered check (user_a < user_b),
  constraint friend_connections_unique_pair unique (user_a, user_b)
);

create index if not exists friend_connections_user_a_idx on public.friend_connections (user_a);
create index if not exists friend_connections_user_b_idx on public.friend_connections (user_b);

create table if not exists public.connection_pets (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.friend_connections (id) on delete cascade,
  pet_type text not null,
  pet_name text not null,
  level integer not null default 1,
  xp integer not null default 0,
  bond_score integer not null default 0,
  hunger integer not null default 100,
  energy integer not null default 100,
  happiness integer not null default 100,
  mood text not null default 'happy',
  stage text not null default 'baby',
  last_state_update timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint connection_pets_one_per_connection unique (connection_id),
  constraint connection_pets_type_check check (pet_type in ('cat', 'dog', 'bunny')),
  constraint connection_pets_mood_check check (
    mood in ('happy', 'hungry', 'tired', 'sad', 'excited', 'sleeping')
  ),
  constraint connection_pets_stage_check check (
    stage in ('baby', 'young', 'adult', 'special')
  ),
  constraint connection_pets_stats_range check (
    hunger between 0 and 100
    and energy between 0 and 100
    and happiness between 0 and 100
    and level >= 1
    and xp >= 0
    and bond_score >= 0
  ),
  constraint connection_pets_name_length check (char_length(trim(pet_name)) between 1 and 32)
);

create index if not exists connection_pets_connection_id_idx
  on public.connection_pets (connection_id);

create table if not exists public.pet_actions (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.connection_pets (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  action_type text not null,
  xp_earned integer not null default 0,
  idempotency_key text,
  created_at timestamptz not null default timezone('utc', now()),
  constraint pet_actions_type_check check (
    action_type in ('create', 'feed', 'play', 'pet', 'drink', 'sleep', 'wake', 'moment_event')
  ),
  constraint pet_actions_idempotency unique (pet_id, user_id, idempotency_key)
);

create index if not exists pet_actions_pet_id_created_idx
  on public.pet_actions (pet_id, created_at desc);

create index if not exists pet_actions_user_id_idx on public.pet_actions (user_id);

insert into public.app_config (key, value)
values (
  'shared_pet',
  jsonb_build_object(
    'action_cooldown_seconds', 3,
    'xp_per_level', 100,
    'actions', jsonb_build_object(
      'feed', jsonb_build_object('hunger', 20, 'happiness', 3, 'xp', 5, 'energy', -2),
      'play', jsonb_build_object('happiness', 10, 'energy', -10, 'xp', 10),
      'pet', jsonb_build_object('happiness', 5, 'bond_score', 2, 'xp', 3),
      'drink', jsonb_build_object('hunger', 8, 'energy', 5, 'xp', 3),
      'sleep', jsonb_build_object('energy', 30, 'mood', 'sleeping', 'xp', 5),
      'wake', jsonb_build_object('mood', 'happy', 'xp', 2)
    ),
    'moment_event', jsonb_build_object('bond_score', 1, 'xp', 2, 'happiness', 2),
    'reaction_event', jsonb_build_object('happiness', 3, 'bond_score', 1, 'xp', 1),
    'activity_event', jsonb_build_object('bond_score', 3, 'xp', 8, 'happiness', 5)
  )
)
on conflict (key) do update set value = excluded.value;

-- Helpers

create or replace function public.is_friend_connection_member(p_connection_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.friend_connections fc
    where fc.id = p_connection_id
      and (fc.user_a = auth.uid() or fc.user_b = auth.uid())
  );
$$;

create or replace function public.are_accepted_friends(p_user_id uuid, p_friend_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.friendships f1
    join public.friendships f2
      on f1.friend_id = f2.user_id
     and f1.user_id = f2.friend_id
    where f1.user_id = p_user_id
      and f1.friend_id = p_friend_id
  )
  and not exists (
    select 1 from public.user_blocks ub
    where (ub.blocker_id = p_user_id and ub.blocked_id = p_friend_id)
       or (ub.blocker_id = p_friend_id and ub.blocked_id = p_user_id)
  );
$$;

create or replace function public.ensure_friend_connection(p_friend_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_low uuid;
  v_high uuid;
  v_id uuid;
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;

  if p_friend_id is null or p_friend_id = v_me then
    raise exception 'Invalid friend';
  end if;

  if not public.are_accepted_friends(v_me, p_friend_id) then
    raise exception 'Not friends';
  end if;

  if v_me < p_friend_id then
    v_low := v_me;
    v_high := p_friend_id;
  else
    v_low := p_friend_id;
    v_high := v_me;
  end if;

  select id into v_id
  from public.friend_connections
  where user_a = v_low and user_b = v_high;

  if v_id is null then
    insert into public.friend_connections (user_a, user_b)
    values (v_low, v_high)
    returning id into v_id;
  end if;

  return v_id;
end;
$$;

create or replace function public.pet_stage_for_level(p_level integer)
returns text
language sql
immutable
as $$
  select case
    when p_level >= 21 then 'special'
    when p_level >= 11 then 'adult'
    when p_level >= 6 then 'young'
    else 'baby'
  end;
$$;

create or replace function public.pet_mood_from_stats(
  p_hunger integer,
  p_energy integer,
  p_happiness integer,
  p_current_mood text
)
returns text
language plpgsql
immutable
as $$
begin
  if p_current_mood = 'sleeping' then
    return 'sleeping';
  end if;
  if p_hunger < 30 then
    return 'hungry';
  end if;
  if p_energy < 25 then
    return 'tired';
  end if;
  if p_happiness < 30 then
    return 'sad';
  end if;
  if p_happiness >= 85 then
    return 'excited';
  end if;
  return 'happy';
end;
$$;

create or replace function public.apply_pet_stat_decay(p_pet public.connection_pets)
returns public.connection_pets
language plpgsql
as $$
declare
  v_hours numeric;
  v_hunger integer;
  v_energy integer;
  v_happiness integer;
begin
  v_hours := extract(epoch from (timezone('utc', now()) - p_pet.last_state_update)) / 3600.0;
  if v_hours < 0.25 then
    return p_pet;
  end if;

  v_hunger := greatest(0, p_pet.hunger - floor(v_hours * 2)::integer);
  v_energy := greatest(0, p_pet.energy - floor(v_hours * 1.5)::integer);
  v_happiness := greatest(0, p_pet.happiness - floor(v_hours)::integer);

  p_pet.hunger := v_hunger;
  p_pet.energy := v_energy;
  p_pet.happiness := v_happiness;
  p_pet.mood := public.pet_mood_from_stats(v_hunger, v_energy, v_happiness, p_pet.mood);
  p_pet.last_state_update := timezone('utc', now());
  return p_pet;
end;
$$;

create or replace function public.pet_row_to_json(p_pet public.connection_pets)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'id', p_pet.id,
    'connection_id', p_pet.connection_id,
    'pet_type', p_pet.pet_type,
    'pet_name', p_pet.pet_name,
    'level', p_pet.level,
    'xp', p_pet.xp,
    'bond_score', p_pet.bond_score,
    'hunger', p_pet.hunger,
    'energy', p_pet.energy,
    'happiness', p_pet.happiness,
    'mood', p_pet.mood,
    'stage', p_pet.stage,
    'last_state_update', p_pet.last_state_update,
    'created_at', p_pet.created_at,
    'updated_at', p_pet.updated_at
  );
$$;

create or replace function public.get_shared_pet_for_friend(p_friend_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_connection_id uuid;
  v_pet public.connection_pets;
begin
  v_connection_id := public.ensure_friend_connection(p_friend_id);

  select * into v_pet
  from public.connection_pets
  where connection_id = v_connection_id;

  if not found then
    return jsonb_build_object('pet', null, 'connection_id', v_connection_id);
  end if;

  v_pet := public.apply_pet_stat_decay(v_pet);
  update public.connection_pets
  set
    hunger = v_pet.hunger,
    energy = v_pet.energy,
    happiness = v_pet.happiness,
    mood = v_pet.mood,
    last_state_update = v_pet.last_state_update,
    updated_at = timezone('utc', now())
  where id = v_pet.id;

  return jsonb_build_object(
    'pet', public.pet_row_to_json(v_pet),
    'connection_id', v_connection_id
  );
end;
$$;

create or replace function public.create_shared_pet(
  p_friend_id uuid,
  p_pet_type text,
  p_pet_name text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_connection_id uuid;
  v_pet public.connection_pets;
begin
  if p_pet_type not in ('cat', 'dog', 'bunny') then
    raise exception 'Invalid pet type';
  end if;

  if trim(p_pet_name) = '' then
    raise exception 'Pet name required';
  end if;

  v_connection_id := public.ensure_friend_connection(p_friend_id);

  if exists (select 1 from public.connection_pets where connection_id = v_connection_id) then
    raise exception 'Pet already exists for this connection';
  end if;

  insert into public.connection_pets (
    connection_id,
    pet_type,
    pet_name,
    level,
    xp,
    bond_score,
    hunger,
    energy,
    happiness,
    mood,
    stage
  )
  values (
    v_connection_id,
    p_pet_type,
    trim(p_pet_name),
    1,
    0,
    0,
    100,
    100,
    100,
    'happy',
    'baby'
  )
  returning * into v_pet;

  insert into public.pet_actions (pet_id, user_id, action_type, xp_earned, idempotency_key)
  values (v_pet.id, auth.uid(), 'create', 0, gen_random_uuid()::text);

  return public.pet_row_to_json(v_pet);
end;
$$;

create or replace function public.perform_pet_action(
  p_pet_id uuid,
  p_action_type text,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pet public.connection_pets;
  v_config jsonb;
  v_actions jsonb;
  v_delta jsonb;
  v_cooldown integer;
  v_last timestamptz;
  v_xp_gain integer := 0;
  v_level integer;
  v_xp_per_level integer := 100;
  v_new_xp integer;
  v_new_level integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_pet from public.connection_pets where id = p_pet_id;
  if not found then
    raise exception 'Pet not found';
  end if;

  if not public.is_friend_connection_member(v_pet.connection_id) then
    raise exception 'Not allowed';
  end if;

  select value into v_config from public.app_config where key = 'shared_pet';
  v_actions := v_config -> 'actions';
  v_cooldown := coalesce((v_config ->> 'action_cooldown_seconds')::integer, 3);
  v_xp_per_level := coalesce((v_config ->> 'xp_per_level')::integer, 100);

  if p_action_type not in ('feed', 'play', 'pet', 'drink', 'sleep', 'wake') then
    raise exception 'Invalid action';
  end if;

  if p_idempotency_key is not null and exists (
    select 1 from public.pet_actions
    where pet_id = p_pet_id
      and user_id = auth.uid()
      and idempotency_key = p_idempotency_key
  ) then
    return public.pet_row_to_json(v_pet);
  end if;

  select max(created_at) into v_last
  from public.pet_actions
  where pet_id = p_pet_id
    and user_id = auth.uid()
    and action_type = p_action_type;

  if v_last is not null and v_last > timezone('utc', now()) - make_interval(secs => v_cooldown) then
    raise exception 'Action on cooldown';
  end if;

  v_pet := public.apply_pet_stat_decay(v_pet);

  if p_action_type = 'sleep' and v_pet.mood = 'sleeping' then
    raise exception 'Already sleeping';
  end if;

  if p_action_type = 'wake' and v_pet.mood <> 'sleeping' then
    raise exception 'Pet is not sleeping';
  end if;

  if p_action_type in ('feed', 'play', 'pet', 'drink') and v_pet.mood = 'sleeping' then
    raise exception 'Pet is sleeping';
  end if;

  v_delta := v_actions -> p_action_type;

  if v_delta ? 'hunger' then
    v_pet.hunger := least(100, greatest(0, v_pet.hunger + (v_delta ->> 'hunger')::integer));
  end if;
  if v_delta ? 'energy' then
    v_pet.energy := least(100, greatest(0, v_pet.energy + (v_delta ->> 'energy')::integer));
  end if;
  if v_delta ? 'happiness' then
    v_pet.happiness := least(100, greatest(0, v_pet.happiness + (v_delta ->> 'happiness')::integer));
  end if;
  if v_delta ? 'bond_score' then
    v_pet.bond_score := v_pet.bond_score + (v_delta ->> 'bond_score')::integer;
  end if;
  if v_delta ? 'xp' then
    v_xp_gain := (v_delta ->> 'xp')::integer;
  end if;
  if v_delta ? 'mood' then
    v_pet.mood := v_delta ->> 'mood';
  else
    v_pet.mood := public.pet_mood_from_stats(
      v_pet.hunger, v_pet.energy, v_pet.happiness, v_pet.mood
    );
  end if;

  v_new_xp := v_pet.xp + v_xp_gain;
  v_new_level := v_pet.level;
  while v_new_xp >= v_xp_per_level and v_new_level < 99 do
    v_new_xp := v_new_xp - v_xp_per_level;
    v_new_level := v_new_level + 1;
  end loop;

  v_pet.xp := v_new_xp;
  v_pet.level := v_new_level;
  v_pet.stage := public.pet_stage_for_level(v_pet.level);
  v_pet.last_state_update := timezone('utc', now());
  v_pet.updated_at := timezone('utc', now());

  update public.connection_pets
  set
    hunger = v_pet.hunger,
    energy = v_pet.energy,
    happiness = v_pet.happiness,
    bond_score = v_pet.bond_score,
    xp = v_pet.xp,
    level = v_pet.level,
    stage = v_pet.stage,
    mood = v_pet.mood,
    last_state_update = v_pet.last_state_update,
    updated_at = v_pet.updated_at
  where id = v_pet.id;

  insert into public.pet_actions (
    pet_id, user_id, action_type, xp_earned, idempotency_key
  )
  values (
    v_pet.id,
    auth.uid(),
    p_action_type,
    v_xp_gain,
    coalesce(p_idempotency_key, gen_random_uuid()::text)
  );

  return public.pet_row_to_json(v_pet);
end;
$$;

create or replace function public.apply_pet_integration_event(
  p_pet_id uuid,
  p_event_type text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pet public.connection_pets;
  v_config jsonb;
  v_delta jsonb;
  v_xp_gain integer := 0;
  v_xp_per_level integer := 100;
  v_new_xp integer;
  v_new_level integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_pet from public.connection_pets where id = p_pet_id;
  if not found then
    raise exception 'Pet not found';
  end if;

  if not public.is_friend_connection_member(v_pet.connection_id) then
    raise exception 'Not allowed';
  end if;

  select value into v_config from public.app_config where key = 'shared_pet';

  v_delta := case p_event_type
    when 'moment_shared' then v_config -> 'moment_event'
    when 'reaction_received' then v_config -> 'reaction_event'
    when 'activity_completed' then v_config -> 'activity_event'
    else null
  end;

  if v_delta is null then
    raise exception 'Invalid event type';
  end if;

  v_pet := public.apply_pet_stat_decay(v_pet);

  if v_delta ? 'happiness' then
    v_pet.happiness := least(100, v_pet.happiness + (v_delta ->> 'happiness')::integer);
  end if;
  if v_delta ? 'bond_score' then
    v_pet.bond_score := v_pet.bond_score + (v_delta ->> 'bond_score')::integer;
  end if;
  if v_delta ? 'xp' then
    v_xp_gain := (v_delta ->> 'xp')::integer;
  end if;

  v_xp_per_level := coalesce((v_config ->> 'xp_per_level')::integer, 100);
  v_new_xp := v_pet.xp + v_xp_gain;
  v_new_level := v_pet.level;
  while v_new_xp >= v_xp_per_level and v_new_level < 99 do
    v_new_xp := v_new_xp - v_xp_per_level;
    v_new_level := v_new_level + 1;
  end loop;

  v_pet.xp := v_new_xp;
  v_pet.level := v_new_level;
  v_pet.stage := public.pet_stage_for_level(v_pet.level);
  v_pet.mood := public.pet_mood_from_stats(
    v_pet.hunger, v_pet.energy, v_pet.happiness, v_pet.mood
  );
  v_pet.updated_at := timezone('utc', now());
  v_pet.last_state_update := timezone('utc', now());

  update public.connection_pets set
    happiness = v_pet.happiness,
    bond_score = v_pet.bond_score,
    xp = v_pet.xp,
    level = v_pet.level,
    stage = v_pet.stage,
    mood = v_pet.mood,
    updated_at = v_pet.updated_at,
    last_state_update = v_pet.last_state_update
  where id = v_pet.id;

  insert into public.pet_actions (pet_id, user_id, action_type, xp_earned)
  values (v_pet.id, auth.uid(), 'moment_event', v_xp_gain);

  return public.pet_row_to_json(v_pet);
end;
$$;

create or replace function public.list_pet_actions(p_pet_id uuid, p_limit integer default 30)
returns jsonb
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  v_pet public.connection_pets;
begin
  select * into v_pet from public.connection_pets where id = p_pet_id;
  if not found then
    raise exception 'Pet not found';
  end if;

  if not public.is_friend_connection_member(v_pet.connection_id) then
    raise exception 'Not allowed';
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', pa.id,
          'user_id', pa.user_id,
          'action_type', pa.action_type,
          'xp_earned', pa.xp_earned,
          'created_at', pa.created_at
        )
        order by pa.created_at desc
      )
      from public.pet_actions pa
      where pa.pet_id = p_pet_id
      limit greatest(1, least(p_limit, 100))
    ),
    '[]'::jsonb
  );
end;
$$;

-- RLS

alter table public.friend_connections enable row level security;
alter table public.connection_pets enable row level security;
alter table public.pet_actions enable row level security;

drop policy if exists "Members view friend connections" on public.friend_connections;
create policy "Members view friend connections"
on public.friend_connections for select
to authenticated
using (user_a = auth.uid() or user_b = auth.uid());

drop policy if exists "Members view connection pets" on public.connection_pets;
create policy "Members view connection pets"
on public.connection_pets for select
to authenticated
using (public.is_friend_connection_member(connection_id));

drop policy if exists "Members view pet actions" on public.pet_actions;
create policy "Members view pet actions"
on public.pet_actions for select
to authenticated
using (
  exists (
    select 1 from public.connection_pets cp
    where cp.id = pet_id
      and public.is_friend_connection_member(cp.connection_id)
  )
);

-- No direct insert/update/delete on pets or actions from client (RPC only)

revoke insert, update, delete on public.connection_pets from authenticated;
revoke insert, update, delete on public.pet_actions from authenticated;
revoke insert, update, delete on public.friend_connections from authenticated;

grant select on public.friend_connections to authenticated;
grant select on public.connection_pets to authenticated;
grant select on public.pet_actions to authenticated;

revoke all on function public.is_friend_connection_member(uuid) from public;
revoke all on function public.are_accepted_friends(uuid, uuid) from public;
revoke all on function public.ensure_friend_connection(uuid) from public;
grant execute on function public.is_friend_connection_member(uuid) to authenticated;
grant execute on function public.ensure_friend_connection(uuid) to authenticated;
grant execute on function public.get_shared_pet_for_friend(uuid) to authenticated;
grant execute on function public.create_shared_pet(uuid, text, text) to authenticated;
grant execute on function public.perform_pet_action(uuid, text, text) to authenticated;
grant execute on function public.apply_pet_integration_event(uuid, text) to authenticated;
grant execute on function public.list_pet_actions(uuid, integer) to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'connection_pets'
  ) then
    alter publication supabase_realtime add table public.connection_pets;
  end if;
end $$;
