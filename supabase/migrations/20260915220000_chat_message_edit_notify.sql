-- Notify recipient when a chat message is edited (while still unread).

create or replace function public.notify_chat_message_edit()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_recipient uuid;
  v_key text;
  v_url text;
begin
  if new.sender_id is null then
    return new;
  end if;

  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if new.edited_at is null or new.edited_at is not distinct from old.edited_at then
    return new;
  end if;

  if new.read_at is not null then
    return new;
  end if;

  select case
    when c.participant_low = new.sender_id then c.participant_high
    else c.participant_low
  end
  into v_recipient
  from public.chat_conversations c
  where c.id = new.conversation_id;

  if v_recipient is null or v_recipient = new.sender_id then
    return new;
  end if;

  begin
    select decrypted_secret into v_key
    from vault.decrypted_secrets
    where name = 'edge_function_key'
    limit 1;

    select decrypted_secret into v_url
    from vault.decrypted_secrets
    where name = 'notify_chat_url'
    limit 1;
  exception
    when others then
      return new;
  end;

  if v_key is null or v_url is null then
    return new;
  end if;

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    body := jsonb_build_object(
      'message_id', new.id,
      'recipient_id', v_recipient,
      'is_edit', true
    ),
    timeout_milliseconds := 5000
  );

  return new;
exception
  when others then
    return new;
end;
$$;

drop trigger if exists chat_messages_edit_notify on public.chat_messages;
create trigger chat_messages_edit_notify
after update on public.chat_messages
for each row
execute function public.notify_chat_message_edit();

revoke all on function public.notify_chat_message_edit() from public;
revoke all on function public.notify_chat_message_edit() from anon;
revoke all on function public.notify_chat_message_edit() from authenticated;
