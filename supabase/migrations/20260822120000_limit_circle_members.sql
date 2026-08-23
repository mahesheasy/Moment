-- A circle can have at most 20 members, including the owner.

create or replace function public.enforce_circle_member_limit()
returns trigger
language plpgsql
as $$
declare
  current_count integer;
begin
  select count(*) into current_count
  from public.circle_members
  where circle_id = new.circle_id;

  if current_count >= 20 then
    raise exception 'A circle can have at most 20 members';
  end if;

  return new;
end;
$$;

drop trigger if exists circle_members_limit on public.circle_members;
create trigger circle_members_limit
before insert on public.circle_members
for each row
execute function public.enforce_circle_member_limit();
