-- Push notification when someone reacts to a chat message.
-- Widen emoji column constraint for full emoji picker support.

alter table public.chat_message_reactions
  drop constraint if exists chat_message_reactions_emoji_check;

alter table public.chat_message_reactions
  add constraint chat_message_reactions_emoji_check
  check (char_length(emoji) between 1 and 32);

do $$
begin
  if not exists (select 1 from vault.secrets where name = 'notify_chat_reaction_url') then
    perform vault.create_secret(
      'https://rqnzwvzziqflgipxiciz.supabase.co/functions/v1/notify-chat-reaction',
      'notify_chat_reaction_url',
      'Webhook for chat message reaction push notifications'
    );
  end if;
end $$;

create or replace function public.notify_chat_message_reaction()
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
  select m.sender_id
  into v_recipient
  from public.chat_messages m
  where m.id = new.message_id;

  if v_recipient is null or v_recipient = new.user_id then
    return new;
  end if;

  begin
    select decrypted_secret into v_key
    from vault.decrypted_secrets
    where name = 'edge_function_key'
    limit 1;

    select decrypted_secret into v_url
    from vault.decrypted_secrets
    where name = 'notify_chat_reaction_url'
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
      'message_id', new.message_id,
      'reactor_id', new.user_id,
      'recipient_id', v_recipient,
      'emoji', new.emoji
    ),
    timeout_milliseconds := 5000
  );

  return new;
exception
  when others then
    return new;
end;
$$;

drop trigger if exists chat_message_reactions_notify on public.chat_message_reactions;
create trigger chat_message_reactions_notify
after insert on public.chat_message_reactions
for each row
execute function public.notify_chat_message_reaction();

revoke all on function public.notify_chat_message_reaction() from public;
revoke all on function public.notify_chat_message_reaction() from anon;
revoke all on function public.notify_chat_message_reaction() from authenticated;
