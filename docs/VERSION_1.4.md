# Version 1.4 — Memory Vault

## Scope

- Saved memories from daily prompt collages
- Memory list (scrapbook cards, not photo grid)
- Memory detail timeline + participants
- Create from circle Today page
- Delete memory (owner)

## Database

Migration: `20260815190000_create_memory_vault.sql`

- `memories` — title, cover, circle/prompt link, date span
- `memory_items` — ordered moments
- `memory_participants` — shared circle members
- RPC: `create_memory_from_prompt_responses`

## App

- `lib/features/memories/` — full domain/data/presentation
- Memories tab: vault cards + recent moments section
- Circle Today: Save as Memory → title dialog → vault
- Memory detail: cover, stats, scrapbook timeline, delete

## Verification

```bash
dart format lib test
flutter analyze
flutter test
```

## Deferred

- Custom memory covers upload (1.8)
- Memory themes/chapters (1.8)
- Premium unlimited memories (1.6)
