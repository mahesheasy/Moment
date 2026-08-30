-- Delete all messages in a 1:1 conversation for a fresh chat restart.

create or replace function public.delete_chat_conversation(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1
    from public.chat_conversations c
    where c.id = p_conversation_id
      and (c.participant_low = v_me or c.participant_high = v_me)
  ) then
    raise exception 'Not a participant in this conversation';
  end if;

  delete from public.chat_typing
  where conversation_id = p_conversation_id;

  delete from public.chat_messages
  where conversation_id = p_conversation_id;

  update public.chat_conversations
  set
    last_message_preview = null,
    last_message_at = null,
    updated_at = timezone('utc', now())
  where id = p_conversation_id;

  insert into public.chat_conversation_settings (
    user_id,
    conversation_id,
    is_hidden,
    is_pinned,
    pinned_at,
    updated_at
  )
  values (
    v_me,
    p_conversation_id,
    true,
    false,
    null,
    timezone('utc', now())
  )
  on conflict (user_id, conversation_id) do update
  set
    is_hidden = true,
    is_pinned = false,
    pinned_at = null,
    updated_at = timezone('utc', now());
end;
$$;

revoke all on function public.delete_chat_conversation(uuid) from public;
grant execute on function public.delete_chat_conversation(uuid) to authenticated;
