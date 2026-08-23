-- Getters were marked STABLE (read-only) but called sync_moment_plus_entitlement,
-- which DELETEs expired entitlements. PostgREST then fails with:
-- "cannot execute DELETE in a read-only transaction".

drop function if exists public.get_widget_preferences();
drop function if exists public.get_moment_plus_offering();
drop function if exists public.get_memory_theme_catalog();

create function public.get_widget_preferences()
returns jsonb
language plpgsql
security definer
set search_path = public
volatile
as $$
declare
  prefs public.widget_preferences;
  is_premium boolean;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

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

create function public.get_moment_plus_offering()
returns jsonb
language plpgsql
security definer
set search_path = public
volatile
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

create function public.get_memory_theme_catalog()
returns jsonb
language plpgsql
security definer
set search_path = public
volatile
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  return jsonb_build_object(
    'themes',
    jsonb_build_array(
      'minimal', 'glass', 'film', 'polaroid', 'midnight',
      'sunset', 'love', 'retro', 'memory'
    ),
    'memory_types',
    jsonb_build_array(
      'prompt', 'circle', 'anniversary', 'birthday', 'trip', 'custom'
    ),
    'is_premium', public.has_moment_plus_entitlement(auth.uid())
  );
end;
$$;

revoke all on function public.get_widget_preferences() from public;
revoke all on function public.get_moment_plus_offering() from public;
revoke all on function public.get_memory_theme_catalog() from public;
revoke all on function public.get_widget_preferences() from anon;
revoke all on function public.get_moment_plus_offering() from anon;
revoke all on function public.get_memory_theme_catalog() from anon;
grant execute on function public.get_widget_preferences() to authenticated;
grant execute on function public.get_moment_plus_offering() to authenticated;
grant execute on function public.get_memory_theme_catalog() to authenticated;
