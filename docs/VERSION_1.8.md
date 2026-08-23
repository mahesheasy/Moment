# Version 1.8 — Advanced Memories

## Scope

- Memory types: prompt, circle, anniversary, birthday, trip, custom
- Memory themes (premium gated beyond minimal)
- Memory captions and memory dates
- Custom cover upload (`memory-covers` bucket) + moment cover picker
- Memory chapters with grouped timeline
- Create memory flow from Memory Vault

## Database

Migration: `20260815230000_create_advanced_memories.sql`

- Extended `memories` columns: `memory_type`, `caption`, `theme`, `cover_storage_path`, `memory_date`
- `memory_chapters` table + `memory_items.chapter_id`
- Storage bucket: `memory-covers`
- RPCs: `get_memory_theme_catalog`, `create_advanced_memory`, `update_memory_advanced`, `upsert_memory_chapter`, `delete_memory_chapter`

## App

- Themed memory cards and detail pages
- `/memories/:id/edit` — caption, theme, date, cover
- Create memory bottom sheet from vault
- Type filters on Memory Vault tab

## Verification

```bash
dart format lib test
flutter analyze
flutter test
```

## Deferred

- Assigning moments to chapters from UI (schema ready)
- AI summaries (2.0+)
