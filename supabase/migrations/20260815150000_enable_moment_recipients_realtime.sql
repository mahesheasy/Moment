-- Enable Supabase Realtime for moment delivery (no push / FCM)

alter publication supabase_realtime add table public.moment_recipients;
