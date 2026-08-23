-- Fix friend request re-send after reject/cancel and add send_friend_request RPC

alter table public.friend_requests
  drop constraint if exists friend_requests_pair_unique;

create unique index if not exists friend_requests_pending_sender_receiver_idx
  on public.friend_requests (sender_id, receiver_id)
  where status = 'pending';

create or replace function public.send_friend_request(p_receiver_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sender uuid := auth.uid();
  v_request_id uuid;
  v_incoming_id uuid;
begin
  if v_sender is null then
    raise exception 'Not authenticated';
  end if;

  if v_sender = p_receiver_id then
    raise exception 'Cannot send a friend request to yourself';
  end if;

  if exists (
    select 1
    from public.friendships
    where user_id = v_sender and friend_id = p_receiver_id
  ) then
    raise exception 'You are already friends';
  end if;

  if exists (
    select 1
    from public.user_blocks b
    where (b.blocker_id = p_receiver_id and b.blocked_id = v_sender)
       or (b.blocker_id = v_sender and b.blocked_id = p_receiver_id)
  ) then
    raise exception 'Cannot send a request to this user';
  end if;

  select id into v_incoming_id
  from public.friend_requests
  where status = 'pending'
    and sender_id = p_receiver_id
    and receiver_id = v_sender
  limit 1;

  if v_incoming_id is not null then
    raise exception 'They already sent you a request. Accept it from Friends.';
  end if;

  select id into v_request_id
  from public.friend_requests
  where status = 'pending'
    and sender_id = v_sender
    and receiver_id = p_receiver_id
  limit 1;

  if v_request_id is not null then
    return v_request_id;
  end if;

  delete from public.friend_requests
  where (
      (sender_id = v_sender and receiver_id = p_receiver_id)
      or (sender_id = p_receiver_id and receiver_id = v_sender)
    )
    and status in ('rejected', 'cancelled');

  insert into public.friend_requests (sender_id, receiver_id, status)
  values (v_sender, p_receiver_id, 'pending')
  returning id into v_request_id;

  return v_request_id;
end;
$$;

revoke all on function public.send_friend_request(uuid) from public;
revoke all on function public.send_friend_request(uuid) from anon;
grant execute on function public.send_friend_request(uuid) to authenticated;
