-- Push notification when a friend request is accepted (notify the original sender).

create or replace function public.notify_friend_request_accepted()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_key text;
  v_url text;
begin
  if old.status is not distinct from 'accepted' then
    return new;
  end if;

  if new.status is distinct from 'accepted' then
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
    where name = 'notify_friend_accepted_url'
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
      'sender_id', new.sender_id,
      'receiver_id', new.receiver_id
    ),
    timeout_milliseconds := 5000
  );

  return new;
exception
  when others then
    return new;
end;
$$;

drop trigger if exists friend_requests_accepted_notify on public.friend_requests;
create trigger friend_requests_accepted_notify
after update on public.friend_requests
for each row
execute function public.notify_friend_request_accepted();

revoke all on function public.notify_friend_request_accepted() from public;
revoke all on function public.notify_friend_request_accepted() from anon;
revoke all on function public.notify_friend_request_accepted() from authenticated;

do $$
begin
  if not exists (select 1 from vault.secrets where name = 'notify_friend_accepted_url') then
    perform vault.create_secret(
      'https://rqnzwvzziqflgipxiciz.supabase.co/functions/v1/notify-friend-accepted',
      'notify_friend_accepted_url',
      'Webhook for friend request accepted push notifications'
    );
  end if;
end $$;
