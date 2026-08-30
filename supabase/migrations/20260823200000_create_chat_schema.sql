-- 1:1 chat (Snap-style messaging) backed by Postgres + Realtime.
-- Push delivery uses existing Firebase FCM pipeline (see chat_messages_notify trigger).

create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  participant_low uuid not null references public.profiles (id) on delete cascade,
  participant_high uuid not null references public.profiles (id) on delete cascade,
  last_message_preview text,
  last_message_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint chat_conversations_ordered check (participant_low < participant_high),
  constraint chat_conversations_unique_pair unique (participant_low, participant_high)
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null default '',
  message_type text not null default 'text',
  media_url text,
  read_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  constraint chat_messages_type_check check (
    message_type in ('text', 'snap', 'image')
  )
);

create index if not exists chat_messages_conversation_created_idx
  on public.chat_messages (conversation_id, created_at desc);

create index if not exists chat_conversations_participant_low_idx
  on public.chat_conversations (participant_low, last_message_at desc nulls last);

create index if not exists chat_conversations_participant_high_idx
  on public.chat_conversations (participant_high, last_message_at desc nulls last);

alter table public.chat_conversations enable row level security;
alter table public.chat_messages enable row level security;

-- Participants can read their conversations.
drop policy if exists "Users can view own chat conversations" on public.chat_conversations;
create policy "Users can view own chat conversations"
on public.chat_conversations for select
to authenticated
using (
  auth.uid() = participant_low or auth.uid() = participant_high
);

drop policy if exists "Users can view messages in own conversations" on public.chat_messages;
create policy "Users can view messages in own conversations"
on public.chat_messages for select
to authenticated
using (
  exists (
    select 1 from public.chat_conversations c
    where c.id = conversation_id
      and (c.participant_low = auth.uid() or c.participant_high = auth.uid())
  )
);

drop policy if exists "Users can send messages to friends" on public.chat_messages;
create policy "Users can send messages to friends"
on public.chat_messages for insert
to authenticated
with check (
  auth.uid() = sender_id
  and exists (
    select 1 from public.chat_conversations c
    where c.id = conversation_id
      and (c.participant_low = auth.uid() or c.participant_high = auth.uid())
      and exists (
        select 1 from public.friendships f
        where f.user_id = auth.uid()
          and f.friend_id = case
            when c.participant_low = auth.uid() then c.participant_high
            else c.participant_low
          end
      )
  )
);

drop policy if exists "Users can mark received messages read" on public.chat_messages;
create policy "Users can mark received messages read"
on public.chat_messages for update
to authenticated
using (
  sender_id != auth.uid()
  and exists (
    select 1 from public.chat_conversations c
    where c.id = conversation_id
      and (c.participant_low = auth.uid() or c.participant_high = auth.uid())
  )
)
with check (
  sender_id != auth.uid()
);

create or replace function public.get_or_create_chat_conversation(p_other_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_low uuid;
  v_high uuid;
  v_id uuid;
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;
  if p_other_user_id is null or p_other_user_id = v_me then
    raise exception 'Invalid chat participant';
  end if;

  if not exists (
    select 1 from public.friendships
    where user_id = v_me and friend_id = p_other_user_id
  ) then
    raise exception 'You can only chat with friends';
  end if;

  v_low := least(v_me, p_other_user_id);
  v_high := greatest(v_me, p_other_user_id);

  select id into v_id
  from public.chat_conversations
  where participant_low = v_low and participant_high = v_high;

  if v_id is not null then
    return v_id;
  end if;

  insert into public.chat_conversations (participant_low, participant_high)
  values (v_low, v_high)
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.get_or_create_chat_conversation(uuid) from public;
grant execute on function public.get_or_create_chat_conversation(uuid) to authenticated;

create or replace function public.chat_touch_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.chat_conversations
  set
    last_message_preview = left(coalesce(new.body, ''), 120),
    last_message_at = new.created_at,
    updated_at = timezone('utc', now())
  where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists chat_messages_touch_conversation on public.chat_messages;
create trigger chat_messages_touch_conversation
after insert on public.chat_messages
for each row execute function public.chat_touch_conversation();

alter publication supabase_realtime add table public.chat_messages;
