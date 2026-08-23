# Version 1.1 — Reactions + Ping

## Database

- `moment_reactions` — one reaction per user per moment (heart, laugh, fire, love, wow)
- `pings` — lightweight nudge to a friend, optional `moment_id` context
- RLS: react/view only on moments you sent or received
- Realtime enabled on both tables (in-app, no push)

## App

- Reaction picker sheet (❤️ 😂 🔥 😍 😮)
- Reaction bar on Home + Moment detail
- Ping sender from Home or detail
- `SocialRepository` Clean Architecture layer

## Skipped

- Push notification when ping arrives (0.7 / FCM later)

Next: **Version 1.2 — Circles**
