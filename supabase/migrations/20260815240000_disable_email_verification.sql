-- Disable email verification requirement for Moment auth.
-- 1. Auto-confirm new auth users at insert time.
-- 2. Backfill any existing unconfirmed users.

create or replace function public.autoconfirm_auth_user()
returns trigger
language plpgsql
security definer
set search_path = auth, public
as $$
begin
  if new.email_confirmed_at is null then
    new.email_confirmed_at := timezone('utc', now());
  end if;

  return new;
end;
$$;

drop trigger if exists autoconfirm_auth_user_trigger on auth.users;

create trigger autoconfirm_auth_user_trigger
before insert on auth.users
for each row
execute function public.autoconfirm_auth_user();

update auth.users
set email_confirmed_at = coalesce(email_confirmed_at, timezone('utc', now()))
where email_confirmed_at is null;

revoke all on function public.autoconfirm_auth_user() from public;
grant execute on function public.autoconfirm_auth_user() to supabase_auth_admin;
