-- Version 1.5: time travel lookups (privacy via existing moment access rules)

create or replace function public.get_time_travel_moments()
returns table (
  years_ago integer,
  moment_id uuid,
  target_date date
)
language sql
security definer
set search_path = public
stable
as $$
  with offsets as (
    select unnest(array[1, 2, 3]) as years_ago
  )
  select
    o.years_ago,
    (
      select m.id
      from public.moments m
      where (
        m.sender_id = auth.uid()
        or exists (
          select 1
          from public.moment_recipients mr
          where mr.moment_id = m.id
            and mr.recipient_id = auth.uid()
        )
      )
      and (timezone('utc', m.created_at))::date = (
        (timezone('utc', now()))::date - make_interval(years => o.years_ago)
      )::date
      order by m.created_at desc
      limit 1
    ) as moment_id,
    ((timezone('utc', now()))::date - make_interval(years => o.years_ago))::date
      as target_date
  from offsets o;
$$;

revoke all on function public.get_time_travel_moments() from public;
revoke all on function public.get_time_travel_moments() from anon;
grant execute on function public.get_time_travel_moments() to authenticated;
