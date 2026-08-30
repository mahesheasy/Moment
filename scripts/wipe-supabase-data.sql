-- Wipes ALL user data from the Moment Supabase project.
-- Keeps schema, app_config, subscription_plans, and daily_prompts (seed content).
-- Also deletes all auth users — everyone must sign up again.
--
-- DATABASE: run this in Supabase Dashboard → SQL Editor.
-- STORAGE: Supabase blocks DELETE FROM storage.objects — run:
--   scripts/wipe-supabase-storage.ps1
--   (needs SUPABASE_SERVICE_ROLE_KEY from Dashboard → Settings → API)
--
-- IRREVERSIBLE. Take a backup first if you need one.

BEGIN;

-- 1. All relational user data (photos in storage are separate — see script above)
TRUNCATE TABLE
  public.chat_message_hidden,
  public.chat_message_reactions,
  public.chat_message_stars,
  public.chat_typing,
  public.chat_messages,
  public.chat_conversation_settings,
  public.chat_conversations,
  public.memory_items,
  public.memory_participants,
  public.memory_chapters,
  public.memories,
  public.prompt_responses,
  public.moment_reactions,
  public.moment_recipients,
  public.pings,
  public.moments,
  public.circle_members,
  public.widget_preferences,
  public.circles,
  public.device_tokens,
  public.friend_requests,
  public.friendships,
  public.user_blocks,
  public.user_reports,
  public.subscriptions,
  public.subscription_entitlements,
  public.profiles
RESTART IDENTITY CASCADE;

-- 2. All accounts
DELETE FROM auth.users;

COMMIT;

-- Verify (should all be 0):
-- SELECT COUNT(*) FROM public.moments;
-- SELECT COUNT(*) FROM auth.users;
-- SELECT COUNT(*) FROM storage.objects;  -- use storage script to clear
