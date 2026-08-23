-- Version 0.4: friends, requests, blocks, reports

create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles (id) on delete cascade,
  receiver_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint friend_requests_status_check check (
    status in ('pending', 'accepted', 'rejected', 'cancelled')
  ),
  constraint friend_requests_no_self check (sender_id != receiver_id),
  constraint friend_requests_pair_unique unique (sender_id, receiver_id)
);

create table if not exists public.friendships (
  user_id uuid not null references public.profiles (id) on delete cascade,
  friend_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, friend_id),
  constraint friendships_no_self check (user_id != friend_id)
);

create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (blocker_id, blocked_id),
  constraint user_blocks_no_self check (blocker_id != blocked_id)
);

create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reported_id uuid not null references public.profiles (id) on delete cascade,
  reason text not null,
  details text,
  created_at timestamptz not null default timezone('utc', now()),
  constraint user_reports_no_self check (reporter_id != reported_id),
  constraint user_reports_reason_length check (char_length(reason) between 3 and 120)
);

create index if not exists friend_requests_receiver_pending_idx
  on public.friend_requests (receiver_id)
  where status = 'pending';

create index if not exists friend_requests_sender_pending_idx
  on public.friend_requests (sender_id)
  where status = 'pending';

create index if not exists friendships_user_id_idx on public.friendships (user_id);

create or replace function public.set_friend_requests_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists friend_requests_set_updated_at on public.friend_requests;
create trigger friend_requests_set_updated_at
before update on public.friend_requests
for each row execute function public.set_friend_requests_updated_at();

alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
alter table public.user_blocks enable row level security;
alter table public.user_reports enable row level security;

-- friend_requests policies
drop policy if exists "Users can view own friend requests" on public.friend_requests;
create policy "Users can view own friend requests"
on public.friend_requests for select
to authenticated
using (auth.uid() = sender_id or auth.uid() = receiver_id);

drop policy if exists "Users can send friend requests" on public.friend_requests;
create policy "Users can send friend requests"
on public.friend_requests for insert
to authenticated
with check (
  auth.uid() = sender_id
  and status = 'pending'
  and not exists (
    select 1 from public.user_blocks b
    where (b.blocker_id = receiver_id and b.blocked_id = sender_id)
       or (b.blocker_id = sender_id and b.blocked_id = receiver_id)
  )
);

drop policy if exists "Receivers can respond to friend requests" on public.friend_requests;
create policy "Receivers can respond to friend requests"
on public.friend_requests for update
to authenticated
using (auth.uid() = receiver_id and status = 'pending')
with check (status in ('accepted', 'rejected'));

drop policy if exists "Senders can cancel friend requests" on public.friend_requests;
create policy "Senders can cancel friend requests"
on public.friend_requests for update
to authenticated
using (auth.uid() = sender_id and status = 'pending')
with check (status = 'cancelled');

-- friendships policies
drop policy if exists "Users can view own friendships" on public.friendships;
create policy "Users can view own friendships"
on public.friendships for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can remove own friendships" on public.friendships;
create policy "Users can remove own friendships"
on public.friendships for delete
to authenticated
using (auth.uid() = user_id);

-- user_blocks policies
drop policy if exists "Users can view own blocks" on public.user_blocks;
create policy "Users can view own blocks"
on public.user_blocks for select
to authenticated
using (auth.uid() = blocker_id);

drop policy if exists "Users can block others" on public.user_blocks;
create policy "Users can block others"
on public.user_blocks for insert
to authenticated
with check (auth.uid() = blocker_id);

drop policy if exists "Users can unblock others" on public.user_blocks;
create policy "Users can unblock others"
on public.user_blocks for delete
to authenticated
using (auth.uid() = blocker_id);

-- user_reports policies
drop policy if exists "Users can submit reports" on public.user_reports;
create policy "Users can submit reports"
on public.user_reports for insert
to authenticated
with check (auth.uid() = reporter_id);

drop policy if exists "Users can view own reports" on public.user_reports;
create policy "Users can view own reports"
on public.user_reports for select
to authenticated
using (auth.uid() = reporter_id);

-- RPC: accept request and create bidirectional friendship
create or replace function public.accept_friend_request(request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  req public.friend_requests%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select * into req
  from public.friend_requests
  where id = request_id
    and receiver_id = auth.uid()
    and status = 'pending'
  for update;

  if not found then
    raise exception 'Friend request not found';
  end if;

  update public.friend_requests
  set status = 'accepted'
  where id = request_id;

  insert into public.friendships (user_id, friend_id)
  values (req.sender_id, req.receiver_id), (req.receiver_id, req.sender_id)
  on conflict do nothing;
end;
$$;

revoke all on function public.accept_friend_request(uuid) from public;
revoke all on function public.accept_friend_request(uuid) from anon;
grant execute on function public.accept_friend_request(uuid) to authenticated;

create or replace function public.remove_friend(friend uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  delete from public.friendships
  where (user_id = auth.uid() and friend_id = friend)
     or (user_id = friend and friend_id = auth.uid());
end;
$$;

revoke all on function public.remove_friend(uuid) from public;
revoke all on function public.remove_friend(uuid) from anon;
grant execute on function public.remove_friend(uuid) to authenticated;
