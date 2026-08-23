-- Friend suggestions ranked by mutual connections (friends-of-friends).

create or replace function public.suggest_friends(p_limit int default 15)
returns table (
  profile_id uuid,
  username text,
  display_name text,
  avatar_url text,
  bio text,
  mutual_count bigint
)
language sql
security definer
set search_path = public
stable
as $$
  with my_friends as (
    select friend_id
    from public.friendships
    where user_id = auth.uid()
  ),
  candidates as (
    select
      f.friend_id as candidate_id,
      count(distinct mf.friend_id) as mutual_count
    from my_friends mf
    join public.friendships f on f.user_id = mf.friend_id
    where f.friend_id != auth.uid()
      and f.friend_id not in (select friend_id from my_friends)
      and not exists (
        select 1
        from public.user_blocks b
        where (b.blocker_id = auth.uid() and b.blocked_id = f.friend_id)
           or (b.blocker_id = f.friend_id and b.blocked_id = auth.uid())
      )
      and not exists (
        select 1
        from public.friend_requests fr
        where fr.status = 'pending'
          and (
            (fr.sender_id = auth.uid() and fr.receiver_id = f.friend_id)
            or (fr.sender_id = f.friend_id and fr.receiver_id = auth.uid())
          )
      )
    group by f.friend_id
  )
  select
    p.id,
    p.username,
    p.display_name,
    p.avatar_url,
    p.bio,
    c.mutual_count
  from candidates c
  join public.profiles p on p.id = c.candidate_id
  order by c.mutual_count desc, p.display_name
  limit greatest(p_limit, 1);
$$;

revoke all on function public.suggest_friends(int) from public;
revoke all on function public.suggest_friends(int) from anon;
grant execute on function public.suggest_friends(int) to authenticated;

create or replace function public.mutual_friend_count(other_id uuid)
returns bigint
language sql
security definer
set search_path = public
stable
as $$
  select count(*)::bigint
  from public.friendships mine
  join public.friendships theirs
    on mine.friend_id = theirs.friend_id
  where mine.user_id = auth.uid()
    and theirs.user_id = other_id;
$$;

revoke all on function public.mutual_friend_count(uuid) from public;
revoke all on function public.mutual_friend_count(uuid) from anon;
grant execute on function public.mutual_friend_count(uuid) to authenticated;
