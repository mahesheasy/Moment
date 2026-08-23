-- Persist the ping type so recent activity matches what the sender chose.

alter table public.pings
  add column if not exists emoji text not null default '👋';

alter table public.pings
  drop constraint if exists pings_emoji_length;

alter table public.pings
  add constraint pings_emoji_length check (char_length(emoji) between 1 and 8);
