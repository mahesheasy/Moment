# Version 0.1 — Project foundation

Completed:

- Flutter app `moment` (`app.moment.moment`)
- Feature-first folders under `lib/app`, `lib/core`, `lib/features`
- GetIt dependency injection
- Compile-time environment config (`env.json` + `--dart-define-from-file`)
- Supabase bootstrap (`publishableKey`, PKCE)
- Firebase no-op bootstrap (real FCM in 0.7)
- Typed failures + `Result`
- App logger with secret redaction
- GoRouter shell and `moment://` deep-link mapping
- Theme shell (`AppColors` / `AppTheme`)
- App lifecycle cubit
- Session cubit wiring (no auth product flow yet)
- Dedicated Supabase project `Moment` (`rqnzwvzziqflgipxiciz`, `ap-south-1`)

Not in this version (by design):

- Product screens
- Auth/profile behavior
- Database tables / RLS
- Camera, widgets, notifications
