# Version 1.5 — Time Travel

## Scope

- Surface moments from 1, 2, and 3 years ago (same calendar day, UTC)
- Privacy: only moments the user already sent or received
- Home teaser + full Time Travel page
- Relive → moment detail

## Database

Migration: `20260815200000_create_time_travel.sql`

- RPC: `get_time_travel_moments()` — returns slots with optional moment_id

## App

- `lib/features/time_travel/` — domain, data, presentation
- Home: compact Time Travel card (nearest match)
- Memories tab: link to full page
- `/time-travel` — all available years with Relive

## Verification

```bash
dart format lib test
flutter analyze
flutter test
```

## Deferred

- Time Travel+ depth for Moment+ (1.6)
- Multi-person / circle-filtered time travel
