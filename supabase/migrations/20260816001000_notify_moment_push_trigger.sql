-- Version 1.9: fire the notify-moment edge function when a moment is delivered

create extension if not exists pg_net with schema extensions;

create or replace function public.notify_moment_recipient()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_sender uuid;
  v_key text;
  v_url text;
begin
  select sender_id into v_sender
  from public.moments
  where id = new.moment_id;

  -- Sending a moment to yourself should not push a notification back.
  if v_sender is null or v_sender = new.recipient_id then
    return new;
  end if;

  begin
    select decrypted_secret into v_key
    from vault.decrypted_secrets
    where name = 'edge_function_key'
    limit 1;

    select decrypted_secret into v_url
    from vault.decrypted_secrets
    where name = 'notify_moment_url'
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
      'moment_id', new.moment_id,
      'recipient_id', new.recipient_id
    ),
    timeout_milliseconds := 5000
  );

  return new;
exception
  -- Push is best-effort: a delivery failure must never roll back the moment.
  when others then
    return new;
end;
$$;

drop trigger if exists moment_recipients_notify on public.moment_recipients;
create trigger moment_recipients_notify
after insert on public.moment_recipients
for each row
execute function public.notify_moment_recipient();

revoke all on function public.notify_moment_recipient() from public;
revoke all on function public.notify_moment_recipient() from anon;
revoke all on function public.notify_moment_recipient() from authenticated;
