-- Realtime for delete-for-me + explicit hidden message policies.

alter publication supabase_realtime add table public.chat_message_hidden;

drop policy if exists "Users can hide messages for themselves" on public.chat_message_hidden;

create policy "Users can view own hidden messages"
on public.chat_message_hidden for select
to authenticated
using (auth.uid() = user_id);

create policy "Users can insert own hidden messages"
on public.chat_message_hidden for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Users can update own hidden messages"
on public.chat_message_hidden for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own hidden messages"
on public.chat_message_hidden for delete
to authenticated
using (auth.uid() = user_id);
