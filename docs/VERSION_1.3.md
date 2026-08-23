# Version 1.3 — Daily Prompts

## Scope

- One global prompt per UTC day (rotating template pool)
- Circle members respond by sending a moment
- Today view with response collage + count
- Save as Memory stubbed for 1.4

## Database

Migration: `20260815180000_create_daily_prompts.sql`

- `daily_prompts` — date + text
- `prompt_responses` — prompt + circle + user + moment
- RPC: `get_todays_prompt()`

## App

- `lib/features/prompts/` — domain, data, presentation
- Home: today's prompt card → pick circle → camera
- Circle detail: prompt card → Today page
- Camera: prompt mode auto-selects circle members
- Today page: collage grid, respond, save-as-memory placeholder

## Verification

```bash
dart format lib test
flutter analyze
flutter test
```

## Deferred

- Save as Memory (Version 1.4)
- Custom prompts for Moment+ (Version 1.6)
