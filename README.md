# Moment

Private social-memory application.

Current product version: **0.2 — Design system + navigation**

## Requirements

- Flutter 3.41.2+ (this machine). Spec baseline is 3.44.7; see [docs/MOMENT_IMPLEMENTATION_STATUS.md](docs/MOMENT_IMPLEMENTATION_STATUS.md).
- A Supabase project with a **publishable** key only

## Setup

1. Copy `env.json.example` to `env.json`.
2. Fill `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.
3. Run:

```powershell
flutter pub get
flutter run --dart-define-from-file=env.json
```

Or use `scripts/run.ps1`.

## Commands

```powershell
dart format .
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=env.json
```

## Architecture

Feature-first Clean Architecture. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

UI never queries Supabase. Use cases and repositories own data access.

## Version rule

Do not implement a later version early. Next: **0.3 Auth + profile**.
