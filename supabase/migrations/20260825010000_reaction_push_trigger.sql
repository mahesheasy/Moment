-- Fire notify-reaction edge function when someone reacts to a moment.

create or replace function public.notify_moment_reaction()
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

  if v_sender is null or v_sender = new.user_id then
    return new;
  end if;

  begin
    select decrypted_secret into v_key
    from vault.decrypted_secrets
    where name = 'edge_function_key'
    limit 1;

    select decrypted_secret into v_url
    from vault.decrypted_secrets
    where name = 'notify_reaction_url'
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
      'reactor_id', new.user_id,
      'reaction', new.reaction
    ),
    timeout_milliseconds := 5000
  );

  return new;
exception
  when others then
    return new;
end;
$$;

drop trigger if exists moment_reactions_notify on public.moment_reactions;
create trigger moment_reactions_notify
after insert on public.moment_reactions
for each row
execute function public.notify_moment_reaction();

revoke all on function public.notify_moment_reaction() from public;
revoke all on function public.notify_moment_reaction() from anon;
revoke all on function public.notify_moment_reaction() from authenticated;
