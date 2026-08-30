-- Register notify-reaction and notify-chat webhook URLs in vault.
-- Mirrors the existing notify_moment_url secret used by moment push.

do $$
begin
  if not exists (select 1 from vault.secrets where name = 'notify_reaction_url') then
    perform vault.create_secret(
      'https://rqnzwvzziqflgipxiciz.supabase.co/functions/v1/notify-reaction',
      'notify_reaction_url',
      'Webhook for reaction push notifications'
    );
  end if;

  if not exists (select 1 from vault.secrets where name = 'notify_chat_url') then
    perform vault.create_secret(
      'https://rqnzwvzziqflgipxiciz.supabase.co/functions/v1/notify-chat',
      'notify_chat_url',
      'Webhook for chat push notifications'
    );
  end if;
end $$;
