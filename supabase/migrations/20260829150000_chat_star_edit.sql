-- Star and edit support for chat messages.

alter table public.chat_messages
  add column if not exists edited_at timestamptz;

create table if not exists public.chat_message_stars (
  message_id uuid not null references public.chat_messages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  starred_at timestamptz not null default timezone('utc', now()),
  primary key (message_id, user_id)
);

create index if not exists chat_message_stars_user_idx
  on public.chat_message_stars (user_id, starred_at desc);

alter table public.chat_message_stars enable row level security;

drop policy if exists "Users can manage own message stars" on public.chat_message_stars;
create policy "Users can manage own message stars"
on public.chat_message_stars for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can view stars in own conversations" on public.chat_message_stars;
create policy "Users can view stars in own conversations"
on public.chat_message_stars for select
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

alter publication supabase_realtime add table public.chat_message_stars;
