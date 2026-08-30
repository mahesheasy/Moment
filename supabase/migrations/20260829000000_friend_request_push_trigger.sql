-- Fire notify-friend-request edge function when a pending friend request is created.

create or replace function public.notify_friend_request()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_key text;
  v_url text;
begin
  if new.status is distinct from 'pending' then
    return new;
  end if;

  if new.sender_id is null or new.receiver_id is null then
    return new;
  end if;

  begin
    select decrypted_secret into v_key
    from vault.decrypted_secrets
    where name = 'edge_function_key'
    limit 1;

    select decrypted_secret into v_url
    from vault.decrypted_secrets
    where name = 'notify_friend_request_url'
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
      'request_id', new.id,
      'recipient_id', new.receiver_id,
      'sender_id', new.sender_id
    ),
    timeout_milliseconds := 5000
  );

  return new;
exception
  when others then
    return new;
end;
$$;

drop trigger if exists friend_requests_notify on public.friend_requests;
create trigger friend_requests_notify
after insert on public.friend_requests
for each row
execute function public.notify_friend_request();

revoke all on function public.notify_friend_request() from public;
revoke all on function public.notify_friend_request() from anon;
revoke all on function public.notify_friend_request() from authenticated;

-- Register notify-friend-request webhook URL in vault.
do $$
begin
  if not exists (select 1 from vault.secrets where name = 'notify_friend_request_url') then
    perform vault.create_secret(
      'https://rqnzwvzziqflgipxiciz.supabase.co/functions/v1/notify-friend-request',
      'notify_friend_request_url',
      'Webhook for friend request push notifications'
    );
  end if;
end $$;
