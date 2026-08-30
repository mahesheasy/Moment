-- Reply, reactions, delete-for-me / delete-for-everyone for chat messages.

alter table public.chat_messages
  add column if not exists reply_to_message_id uuid
    references public.chat_messages (id) on delete set null,
  add column if not exists deleted_for_everyone_at timestamptz;

create index if not exists chat_messages_reply_to_idx
  on public.chat_messages (reply_to_message_id)
  where reply_to_message_id is not null;

create table if not exists public.chat_message_hidden (
  message_id uuid not null references public.chat_messages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  hidden_at timestamptz not null default timezone('utc', now()),
  primary key (message_id, user_id)
);

create table if not exists public.chat_message_reactions (
  message_id uuid not null references public.chat_messages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  emoji text not null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint chat_message_reactions_emoji_check check (char_length(emoji) between 1 and 8),
  primary key (message_id, user_id)
);

create index if not exists chat_message_reactions_message_idx
  on public.chat_message_reactions (message_id);

alter table public.chat_message_hidden enable row level security;
alter table public.chat_message_reactions enable row level security;

-- Sender can soft-delete own messages (delete for everyone).
drop policy if exists "Users can delete own messages for everyone" on public.chat_messages;
create policy "Users can delete own messages for everyone"
on public.chat_messages for update
to authenticated
using (
  auth.uid() = sender_id
  and exists (
    select 1 from public.chat_conversations c
    where c.id = conversation_id
      and (c.participant_low = auth.uid() or c.participant_high = auth.uid())
  )
)
with check (auth.uid() = sender_id);

drop policy if exists "Users can hide messages for themselves" on public.chat_message_hidden;
create policy "Users can hide messages for themselves"
on public.chat_message_hidden for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can view reactions in own conversations" on public.chat_message_reactions;
create policy "Users can view reactions in own conversations"
on public.chat_message_reactions for select
to authenticated
using (
  exists (
    select 1
    from public.chat_messages m
    join public.chat_conversations c on c.id = m.conversation_id
    where m.id = message_id
      and (c.participant_low = auth.uid() or c.participant_high = auth.uid())
  )
);

drop policy if exists "Users can react in own conversations" on public.chat_message_reactions;
create policy "Users can react in own conversations"
on public.chat_message_reactions for insert
to authenticated
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.chat_messages m
    join public.chat_conversations c on c.id = m.conversation_id
    where m.id = message_id
      and (c.participant_low = auth.uid() or c.participant_high = auth.uid())
  )
);

drop policy if exists "Users can update own reactions" on public.chat_message_reactions;
create policy "Users can update own reactions"
on public.chat_message_reactions for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can remove own reactions" on public.chat_message_reactions;
create policy "Users can remove own reactions"
on public.chat_message_reactions for delete
to authenticated
using (auth.uid() = user_id);

create or replace function public.chat_touch_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_preview text;
begin
  if TG_OP = 'INSERT' then
    v_preview := left(coalesce(new.body, ''), 120);
    update public.chat_conversations
    set
      last_message_preview = v_preview,
      last_message_at = new.created_at,
      updated_at = timezone('utc', now())
    where id = new.conversation_id;
    return new;
  end if;

  if TG_OP = 'UPDATE'
    and new.deleted_for_everyone_at is not null
    and old.deleted_for_everyone_at is null then
    select case
      when c.last_message_at = new.created_at then 'This message was deleted'
      else c.last_message_preview
    end
    into v_preview
    from public.chat_conversations c
    where c.id = new.conversation_id;

    update public.chat_conversations
    set
      last_message_preview = coalesce(v_preview, 'This message was deleted'),
      updated_at = timezone('utc', now())
    where id = new.conversation_id;
  end if;

  return new;
end;
$$;

drop trigger if exists chat_messages_touch_conversation on public.chat_messages;
create trigger chat_messages_touch_conversation
after insert or update on public.chat_messages
for each row execute function public.chat_touch_conversation();

alter publication supabase_realtime add table public.chat_message_reactions;
