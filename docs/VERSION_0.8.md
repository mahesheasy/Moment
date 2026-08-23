# Version 0.8 — Android widget

## Native (Kotlin + Jetpack Glance)

- `MomentGlanceWidget` — photo-first home screen widget
- `MomentWidgetReceiver` — App Widget provider
- `WidgetBridgePlugin` — MethodChannel `app.moment/widget`
- Tap opens `moment://moment/{id}` deep link

## Flutter bridge

- `AndroidWidgetBridge` syncs latest received moment image + sender to native
- Called from `HomeCubit` after home loads

## In-app realtime (no FCM)

- `MomentRealtimeSubscriber` listens to `moment_recipients` inserts
- Home auto-refreshes when a new moment arrives (app open)

## Skipped (for now)

- FCM / push notifications (0.7)
- iOS WidgetKit (0.9)

## Try it

1. Build APK: `flutter build apk`
2. Install on device/emulator
3. Long-press home screen → Widgets → **Moment**
4. Receive a moment in-app — widget updates on next home load

Next: **1.1 Reactions + Ping** (or 0.7 push when Firebase is ready)
