-- Create profile row when a new auth user is created (supports email confirmation flow)

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_username text;
  requested_display_name text;
begin
  requested_username := lower(trim(coalesce(new.raw_user_meta_data->>'username', '')));
  requested_display_name := trim(coalesce(new.raw_user_meta_data->>'display_name', ''));

  if requested_username = '' or requested_username !~ '^[a-z0-9_]{3,30}$' then
    requested_username := 'user_' || substr(replace(new.id::text, '-', ''), 1, 8);
  end if;

  if requested_display_name = '' then
    requested_display_name := split_part(new.email, '@', 1);
  end if;

  insert into public.profiles (id, username, display_name)
  values (new.id, requested_username, requested_display_name)
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
