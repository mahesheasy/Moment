-- Public username availability check for registration (anon + authenticated).

create or replace function public.is_username_available(candidate text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if candidate is null or candidate !~ '^[a-z0-9_]{3,30}$' then
    return false;
  end if;

  return not exists (
    select 1
    from public.profiles
    where username = candidate
  );
end;
$$;

revoke all on function public.is_username_available(text) from public;
grant execute on function public.is_username_available(text) to anon, authenticated;
