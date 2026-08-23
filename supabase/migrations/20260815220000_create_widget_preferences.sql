-- Version 1.7: Premium widget preferences (themes, accent, mode)

create table if not exists public.widget_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  theme text not null default 'minimal',
  accent_color text not null default '#C4A484',
  typography text not null default 'default',
  widget_mode text not null default 'latest',
  selected_person_id uuid references public.profiles (id) on delete set null,
  selected_circle_id uuid references public.circles (id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  constraint widget_preferences_theme_check check (
    theme in (
      'minimal',
      'glass',
      'film',
      'polaroid',
      'midnight',
      'sunset',
      'love',
      'retro',
      'memory'
    )
  ),
  constraint widget_preferences_typography_check check (
    typography in ('default', 'serif', 'rounded', 'mono')
  ),
  constraint widget_preferences_mode_check check (
    widget_mode in ('latest', 'person', 'circle')
  ),
  constraint widget_preferences_accent_check check (
    accent_color ~ '^#[0-9A-Fa-f]{6}$'
  )
);

create index if not exists widget_preferences_person_idx
  on public.widget_preferences (selected_person_id);

create index if not exists widget_preferences_circle_idx
  on public.widget_preferences (selected_circle_id);

alter table public.widget_preferences enable row level security;

drop policy if exists "Users can view own widget preferences" on public.widget_preferences;
create policy "Users can view own widget preferences"
on public.widget_preferences for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own widget preferences" on public.widget_preferences;
create policy "Users can insert own widget preferences"
on public.widget_preferences for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own widget preferences" on public.widget_preferences;
create policy "Users can update own widget preferences"
on public.widget_preferences for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create or replace function public.has_moment_plus_entitlement(p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.subscription_entitlements se
    where se.user_id = p_user_id
      and se.entitlement_key = 'moment_plus'
      and (se.expires_at is null or se.expires_at > timezone('utc', now()))
  );
$$;

create or replace function public.get_widget_preferences()
returns jsonb
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  prefs public.widget_preferences;
  is_premium boolean;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  perform public.sync_moment_plus_entitlement(auth.uid());
  is_premium := public.has_moment_plus_entitlement(auth.uid());

  select * into prefs
  from public.widget_preferences
  where user_id = auth.uid();

  if not found then
    return jsonb_build_object(
      'preferences',
      jsonb_build_object(
        'theme', 'minimal',
        'accent_color', '#C4A484',
        'typography', 'default',
        'widget_mode', 'latest',
        'selected_person_id', null,
        'selected_circle_id', null
      ),
      'is_premium', is_premium,
      'themes',
      jsonb_build_array(
        'minimal', 'glass', 'film', 'polaroid', 'midnight',
        'sunset', 'love', 'retro', 'memory'
      ),
      'typography_options',
      jsonb_build_array('default', 'serif', 'rounded', 'mono'),
      'widget_modes',
      jsonb_build_array('latest', 'person', 'circle')
    );
  end if;

  if not is_premium then
    return jsonb_build_object(
      'preferences',
      jsonb_build_object(
        'theme', 'minimal',
        'accent_color', '#C4A484',
        'typography', 'default',
        'widget_mode', 'latest',
        'selected_person_id', null,
        'selected_circle_id', null
      ),
      'is_premium', false,
      'saved_preferences',
      jsonb_build_object(
        'theme', prefs.theme,
        'accent_color', prefs.accent_color,
        'typography', prefs.typography,
        'widget_mode', prefs.widget_mode,
        'selected_person_id', prefs.selected_person_id,
        'selected_circle_id', prefs.selected_circle_id
      ),
      'themes',
      jsonb_build_array(
        'minimal', 'glass', 'film', 'polaroid', 'midnight',
        'sunset', 'love', 'retro', 'memory'
      ),
      'typography_options',
      jsonb_build_array('default', 'serif', 'rounded', 'mono'),
      'widget_modes',
      jsonb_build_array('latest', 'person', 'circle')
    );
  end if;

  return jsonb_build_object(
    'preferences',
    jsonb_build_object(
      'theme', prefs.theme,
      'accent_color', prefs.accent_color,
      'typography', prefs.typography,
      'widget_mode', prefs.widget_mode,
      'selected_person_id', prefs.selected_person_id,
      'selected_circle_id', prefs.selected_circle_id
    ),
    'is_premium', true,
    'themes',
    jsonb_build_array(
      'minimal', 'glass', 'film', 'polaroid', 'midnight',
      'sunset', 'love', 'retro', 'memory'
    ),
    'typography_options',
    jsonb_build_array('default', 'serif', 'rounded', 'mono'),
    'widget_modes',
    jsonb_build_array('latest', 'person', 'circle')
  );
end;
$$;

create or replace function public.upsert_widget_preferences(
  p_theme text,
  p_accent_color text,
  p_typography text,
  p_widget_mode text,
  p_selected_person_id uuid default null,
  p_selected_circle_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  is_premium boolean;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  perform public.sync_moment_plus_entitlement(auth.uid());
  is_premium := public.has_moment_plus_entitlement(auth.uid());

  if not is_premium then
    raise exception 'Moment+ required for premium widget customization';
  end if;

  if p_theme not in (
    'minimal', 'glass', 'film', 'polaroid', 'midnight',
    'sunset', 'love', 'retro', 'memory'
  ) then
    raise exception 'Invalid theme';
  end if;

  if p_typography not in ('default', 'serif', 'rounded', 'mono') then
    raise exception 'Invalid typography';
  end if;

  if p_widget_mode not in ('latest', 'person', 'circle') then
    raise exception 'Invalid widget mode';
  end if;

  if p_accent_color !~ '^#[0-9A-Fa-f]{6}$' then
    raise exception 'Invalid accent color';
  end if;

  if p_widget_mode = 'person' and p_selected_person_id is null then
    raise exception 'Select a person for person mode';
  end if;

  if p_widget_mode = 'circle' and p_selected_circle_id is null then
    raise exception 'Select a circle for circle mode';
  end if;

  if p_selected_person_id is not null and not exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and (
        (f.requester_id = auth.uid() and f.addressee_id = p_selected_person_id)
        or (f.addressee_id = auth.uid() and f.requester_id = p_selected_person_id)
      )
  ) then
    raise exception 'Selected person must be a friend';
  end if;

  if p_selected_circle_id is not null and not exists (
    select 1 from public.circle_members cm
    where cm.circle_id = p_selected_circle_id
      and cm.user_id = auth.uid()
  ) then
    raise exception 'Selected circle must be a circle you belong to';
  end if;

  insert into public.widget_preferences (
    user_id,
    theme,
    accent_color,
    typography,
    widget_mode,
    selected_person_id,
    selected_circle_id,
    updated_at
  )
  values (
    auth.uid(),
    p_theme,
    p_accent_color,
    p_typography,
    p_widget_mode,
    case when p_widget_mode = 'person' then p_selected_person_id else null end,
    case when p_widget_mode = 'circle' then p_selected_circle_id else null end,
    timezone('utc', now())
  )
  on conflict (user_id) do update set
    theme = excluded.theme,
    accent_color = excluded.accent_color,
    typography = excluded.typography,
    widget_mode = excluded.widget_mode,
    selected_person_id = excluded.selected_person_id,
    selected_circle_id = excluded.selected_circle_id,
    updated_at = excluded.updated_at;

  return public.get_widget_preferences();
end;
$$;

revoke all on function public.has_moment_plus_entitlement(uuid) from public;
revoke all on function public.get_widget_preferences() from public;
revoke all on function public.upsert_widget_preferences(text, text, text, text, uuid, uuid) from public;
revoke all on function public.has_moment_plus_entitlement(uuid) from anon;
revoke all on function public.get_widget_preferences() from anon;
revoke all on function public.upsert_widget_preferences(text, text, text, text, uuid, uuid) from anon;
grant execute on function public.has_moment_plus_entitlement(uuid) to authenticated;
grant execute on function public.get_widget_preferences() to authenticated;
grant execute on function public.upsert_widget_preferences(text, text, text, text, uuid, uuid) to authenticated;
