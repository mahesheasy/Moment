# Version 1.2 — Circles

## Scope

- Circle types: Us, Squad, Family, College, Custom
- Supabase-backed circles + membership
- List, create, detail with add/remove members (friends only)

## Database

Migration: `20260815170000_create_circles_schema.sql`

- `circles` — name, type, emoji, owner
- `circle_members` — membership + owner role
- RLS: members view; owners manage
- RPC: `create_circle_with_owner`

## App

- `lib/features/circles/` — domain, data, presentation
- Circles tab loads from Supabase
- Create circle sheet with type + friend picker
- Circle detail: members list, add/remove

## Verification

```bash
dart format lib test
flutter analyze
flutter test
```

## Deferred

- Send moment to entire circle from camera (expand member IDs)
- Circle-specific moment feed
