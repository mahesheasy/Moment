-- Shared pet RPCs + RLS (companion to 20260927120000_shared_pet.sql)

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
