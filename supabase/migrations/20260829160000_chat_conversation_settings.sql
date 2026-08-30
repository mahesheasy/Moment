-- Per-user conversation preferences: pin, mute, hide (delete from inbox).

create table if not exists public.chat_conversation_settings (
  user_id uuid not null references public.profiles (id) on delete cascade,
  conversation_id uuid not null references public.chat_conversations (id) on delete cascade,
  is_pinned boolean not null default false,
  is_muted boolean not null default false,
  is_hidden boolean not null default false,
  pinned_at timestamptz,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, conversation_id)
);

create index if not exists chat_conversation_settings_user_idx
  on public.chat_conversation_settings (user_id);

alter table public.chat_conversation_settings enable row level security;

drop policy if exists "Users manage own conversation settings"
  on public.chat_conversation_settings;
create policy "Users manage own conversation settings"
on public.chat_conversation_settings for all
to authenticated
using (user_id = auth.uid())
with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.chat_conversations c
    where c.id = conversation_id
      and (c.participant_low = auth.uid() or c.participant_high = auth.uid())
  )
);

-- Realtime so inbox refreshes when settings change.
alter publication supabase_realtime add table public.chat_conversation_settings;
