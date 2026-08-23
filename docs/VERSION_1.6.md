# Version 1.6 — Moment+

## Scope

- Remote subscription plan config (not hardcoded prices)
- Subscriptions + entitlements schema
- Moment+ offering page with dynamic plans
- Checkout placeholder (App Store / Play Billing later)
- Free tier memory limit gate (3 saved memories)

## Database

Migration: `20260815210000_create_subscriptions.sql`

- `subscription_plans` — remote prices (seed ₹99/mo, ₹699/yr)
- `app_config` — free tier limits
- `subscriptions`, `subscription_entitlements`
- RPCs: `get_moment_plus_offering`, `request_moment_plus_checkout`

## App

- `lib/features/subscription/` — domain, data, presentation
- Premium page with plan picker + feature list
- Memory save blocked at free limit with upgrade message

## Verification

```bash
dart format lib test
flutter analyze
flutter test
```

## Deferred

- Real IAP (App Store / Play Billing)
- Premium widgets/themes (1.7)
- Entitlement admin grant UI
