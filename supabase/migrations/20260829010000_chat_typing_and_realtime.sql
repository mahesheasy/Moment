-- Typing indicators + realtime for inbox updates.

create table if not exists public.chat_typing (
  conversation_id uuid not null references public.chat_conversations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (conversation_id, user_id)
);

create index if not exists chat_typing_conversation_idx
  on public.chat_typing (conversation_id);

alter table public.chat_typing enable row level security;

drop policy if exists "Participants can view typing in own conversations" on public.chat_typing;
create policy "Participants can view typing in own conversations"
on public.chat_typing for select
to authenticated
using (
  exists (
    select 1 from public.chat_conversations c
    where c.id = conversation_id
      and (c.participant_low = auth.uid() or c.participant_high = auth.uid())
  )
);

drop policy if exists "Users can upsert own typing status" on public.chat_typing;
create policy "Users can upsert own typing status"
on public.chat_typing for insert
to authenticated
with check (
  auth.uid() = user_id
  and exists (
    select 1 from public.chat_conversations c
    where c.id = conversation_id
      and (c.participant_low = auth.uid() or c.participant_high = auth.uid())
  )
);

drop policy if exists "Users can update own typing status" on public.chat_typing;
create policy "Users can update own typing status"
on public.chat_typing for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can clear own typing status" on public.chat_typing;
create policy "Users can clear own typing status"
on public.chat_typing for delete
to authenticated
using (auth.uid() = user_id);

do $body$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_typing'
  ) then
    alter publication supabase_realtime add table public.chat_typing;
  end if;
end $body$;

do $body$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_conversations'
  ) then
    alter publication supabase_realtime add table public.chat_conversations;
  end if;
end $body$;
