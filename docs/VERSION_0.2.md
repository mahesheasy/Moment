# Version 0.2 — Design system + navigation

## Design system

- `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`
- `AppDurations` / `AppAnimations`, `AppIcons`, `AppTheme`
- `AppBreakpoints` for phone and tablet layouts

## Reusable components

- `MomentButton`, `MomentTextButton`, `MomentIconButton`
- `MomentAvatar`, `MomentImage`, `MomentCard`
- `MomentBottomSheet`, `MomentDialog`, `MomentChip`, `MomentBadge`
- `MomentLoading`, `MomentShimmer`, `MomentErrorState`, `MomentEmptyState`
- `MomentScaffold`, `MomentAppBar`, `MomentNavigationBar`

## Visual-only screens

- Splash → Onboarding → Home shell
- Login, Register
- Home (photo-first, not a feed)
- Circles, Memories, Profile
- Camera placeholder (capture + preview + audience)
- Moment detail, Settings

## Navigation

Main shell tabs: **Home · Circles · Memories · Profile**

Camera opens as a full-screen overlay via the center capsule button.

Overlay routes (above shell): camera, moment detail, circle/memory detail, settings, profile edit, premium.

## Preview data

`lib/core/preview/preview_data.dart` supplies visual-only mock content. Not used in production flows.

## Not in this version

- Supabase auth behavior
- Real camera / gallery
- Backend data

Next: **Version 0.3 — Auth + profile**
