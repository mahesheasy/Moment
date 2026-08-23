-- Widget privacy is available to every user, not only Moment+.

alter table public.widget_preferences
  add column if not exists privacy_mode text not null default 'full',
  add column if not exists show_sender boolean not null default true,
  add column if not exists show_timestamp boolean not null default true,
  add column if not exists show_captions boolean not null default false,
  add column if not exists lock_screen_privacy boolean not null default true,
  add column if not exists paused boolean not null default false;

alter table public.widget_preferences
  drop constraint if exists widget_preferences_privacy_check;

alter table public.widget_preferences
  add constraint widget_preferences_privacy_check check (
    privacy_mode in ('full', 'blur', 'private')
  );

create or replace function public.get_widget_preferences()
returns jsonb
language plpgsql
security definer
set search_path = public
volatile
as $$
declare
  prefs public.widget_preferences;
  is_premium boolean;
  privacy jsonb;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  is_premium := public.has_moment_plus_entitlement(auth.uid());

  select * into prefs
  from public.widget_preferences
  where user_id = auth.uid();

  if not found then
    privacy := jsonb_build_object(
      'privacy_mode', 'full',
      'show_sender', true,
      'show_timestamp', true,
      'show_captions', false,
      'lock_screen_privacy', true,
      'paused', false
    );
    return jsonb_build_object(
      'preferences',
      jsonb_build_object(
        'theme', 'minimal',
        'accent_color', '#C4A484',
        'typography', 'default',
        'widget_mode', 'latest',
        'selected_person_id', null,
        'selected_circle_id', null
      ) || privacy,
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

  privacy := jsonb_build_object(
    'privacy_mode', prefs.privacy_mode,
    'show_sender', prefs.show_sender,
    'show_timestamp', prefs.show_timestamp,
    'show_captions', prefs.show_captions,
    'lock_screen_privacy', prefs.lock_screen_privacy,
    'paused', prefs.paused
  );

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
      ) || privacy,
      'is_premium', false,
      'saved_preferences',
      jsonb_build_object(
        'theme', prefs.theme,
        'accent_color', prefs.accent_color,
        'typography', prefs.typography,
        'widget_mode', prefs.widget_mode,
        'selected_person_id', prefs.selected_person_id,
        'selected_circle_id', prefs.selected_circle_id
      ) || privacy,
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
    ) || privacy,
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

create or replace function public.upsert_widget_privacy(
  p_privacy_mode text,
  p_show_sender boolean,
  p_show_timestamp boolean,
  p_show_captions boolean,
  p_lock_screen_privacy boolean,
  p_paused boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if p_privacy_mode not in ('full', 'blur', 'private') then
    raise exception 'Invalid privacy mode';
  end if;

  insert into public.widget_preferences (
    user_id,
    privacy_mode,
    show_sender,
    show_timestamp,
    show_captions,
    lock_screen_privacy,
    paused,
    updated_at
  )
  values (
    auth.uid(),
    p_privacy_mode,
    p_show_sender,
    p_show_timestamp,
    p_show_captions,
    p_lock_screen_privacy,
    p_paused,
    timezone('utc', now())
  )
  on conflict (user_id) do update set
    privacy_mode = excluded.privacy_mode,
    show_sender = excluded.show_sender,
    show_timestamp = excluded.show_timestamp,
    show_captions = excluded.show_captions,
    lock_screen_privacy = excluded.lock_screen_privacy,
    paused = excluded.paused,
    updated_at = excluded.updated_at;

  return public.get_widget_preferences();
end;
$$;

revoke all on function public.upsert_widget_privacy(text, boolean, boolean, boolean, boolean, boolean) from public;
revoke all on function public.upsert_widget_privacy(text, boolean, boolean, boolean, boolean, boolean) from anon;
grant execute on function public.upsert_widget_privacy(text, boolean, boolean, boolean, boolean, boolean) to authenticated;
