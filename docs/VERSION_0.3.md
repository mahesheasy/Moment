# Version 0.3 — Auth + profile

## Supabase

- `public.profiles` table with username uniqueness, format checks, display name, avatar URL, bio
- RLS: authenticated users can read all profiles; insert/update/delete own row only
- `avatars` private storage bucket with per-user folder RLS
- `handle_new_user()` trigger on `auth.users` insert (profile from signup metadata)
- `delete_own_account()` RPC for authenticated account deletion
- Security hardening migration: function `search_path`, RPC execute grants

## Auth (Clean Architecture)

- Domain: `AuthRepository`, validators, login/register/logout/reset/delete use cases
- Data: `AuthRemoteDataSource`, `AuthRepositoryImpl` (Supabase Auth)
- Presentation: `LoginCubit`, `RegisterCubit`, wired login/register pages
- Email confirmation flow: register without session → login with info snackbar
- Forgot password sheet on login

## Profile

- Domain: `UserProfile`, `ProfileUpdate`, `ProfileRepository`, get/update/username check use cases
- Data: `ProfileRemoteDataSource`, `ProfileRepositoryImpl`
- Presentation: `ProfileCubit`, `AccountCubit`
- Profile tab loads real profile; edit screen saves display name, username, bio
- Settings: sign out, delete account with confirmation dialog

## Session + routing

- `SessionCubit` listens to `AuthRepository.authStateChanges`
- Splash restores session then routes home or onboarding
- Router redirects: unauthenticated → login; authenticated on auth routes → home

## Env

- `EnvLoader` tries dart-defines first, then bundled `env.json` asset in debug/profile

## Not in this version

- Avatar upload UI (storage bucket exists)
- Friends (0.4)
- Real camera / moments (0.5+)

Next: **Version 0.4 — Friends**
