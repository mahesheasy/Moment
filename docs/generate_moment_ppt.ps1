# Generates Moment App complete documentation PowerPoint
$outputPath = Join-Path $PSScriptRoot "Moment_App_Complete_Documentation.pptx"

$slides = @(
    @{
        Layout = 1
        Title = "Moment"
        Body = "Complete Application Documentation`nEnd-to-End Feature Overview`n`nVersion 1.8.1 | Private Social-Memory App`nSeptember 2026"
    }
    @{
        Title = "Executive Summary"
        Body = @(
            "Moment is a private social-memory app - photo-first, not a feed"
            "Users capture moments and send them to close friends, not public followers"
            "Core pillars: Moments, Friends, Circles, Memories, Chat, Android Home Widget"
            "Backend: Supabase (Auth, Postgres, Storage, Realtime, Edge Functions)"
            "Client: Flutter (iOS + Android) with Clean Architecture + BLoC"
            "Current status: Version 1.8 complete - product validation before 2.0 AI features"
        )
    }
    @{
        Title = "Product Vision"
        Body = @(
            "Private by design - moments shared only with chosen people"
            "Home screen widget acts as a smart notification surface (newest unread only)"
            "Circles for family, squad, college groups with daily prompts"
            "Memory Vault - save collages and life chapters as themed scrapbooks"
            "Moment+ premium tier for customization, unlimited memories, circles"
            "Not a social feed - camera-first home, swipe-up for memories overlay"
        )
    }
    @{
        Title = "Technology Stack"
        Body = @(
            "Flutter 3.11+ | Dart SDK ^3.11.0 | App ID: app.moment.moment"
            "State: flutter_bloc | Routing: go_router | DI: get_it"
            "Backend: supabase_flutter (Auth PKCE, Postgres, Storage, Realtime)"
            "Camera: camera + image_picker | QR: qr_flutter + mobile_scanner"
            "Android Widget: Kotlin + Jetpack Glance + WorkManager + FCM"
            "Push: Firebase Cloud Messaging via Supabase Edge Functions"
            "Fonts: Poppins | Theme: Dark + pink/coral accent"
        )
    }
    @{
        Title = "Architecture"
        Body = @(
            "Feature-first Clean Architecture under lib/"
            "  app/ - bootstrap, DI, router, lifecycle, main shell"
            "  core/ - config, errors, theme, widget bridge, deep links"
            "  features/ - auth, profile, friends, circles, moments, memories, chat, subscription, settings"
            "Data flow: Page -> Cubit -> Repository -> DataSource -> Supabase RPC/REST"
            "Result<T> pattern for typed success/failure handling"
            "Security: publishable key only on client; RLS on all product tables"
        )
    }
    @{
        Title = "Version Roadmap (0.1 -> 1.8)"
        Body = @(
            "0.1 - Project foundation (DI, env, Supabase bootstrap, router shell)"
            "0.2 - Design system + navigation shell (visual screens)"
            "0.3 - Auth + profile (Supabase profiles, RLS, session routing)"
            "0.4 - Friends (requests, block, report, friend profiles)"
            "0.5 - Camera + moment creation (gallery, upload, audience picker)"
            "0.6 - Moment delivery + history (seen state, moment detail)"
            "0.8 - Android home widget (Glance, MethodChannel bridge)"
            "1.1 - Reactions + Pings | 1.2 - Circles | 1.3 - Daily Prompts"
            "1.4 - Memory Vault | 1.5 - Time Travel | 1.6 - Moment+ Premium"
            "1.7 - Premium widget themes | 1.8 - Advanced Memories"
        )
    }
    @{
        Title = "v0.1-0.2: Foundation & Design System"
        Body = @(
            "GetIt dependency injection + compile-time env (env.json)"
            "Supabase bootstrap with PKCE; Firebase no-op until push (0.7+)"
            "GoRouter shell + moment:// deep-link mapping"
            "Design tokens: AppColors, AppTypography, AppSpacing, AppRadius"
            "Reusable UI: MomentButton, MomentCard, MomentBottomSheet, MomentScaffold"
            "Main shell tabs: Home | Circles | Chat | Profile (Memories via swipe overlay)"
            "Camera opens as full-screen overlay from center capsule button"
        )
    }
    @{
        Title = "v0.3: Authentication & Profile"
        Body = @(
            "Supabase Auth: email/password login, register, forgot password"
            "profiles table: username (unique), display name, avatar URL, bio"
            "RLS: read all profiles; write own row only"
            "avatars private storage bucket with per-user folder RLS"
            "handle_new_user() trigger creates profile on signup"
            "delete_own_account() RPC for account deletion"
            "SessionCubit: splash -> restore session -> home or login/onboarding"
            "Profile edit: display name, username, bio | Settings: sign out, delete"
        )
    }
    @{
        Title = "v0.4: Friends System"
        Body = @(
            "Tables: friend_requests, friendships, user_blocks, user_reports"
            "Search users by username -> send/accept/reject/cancel requests"
            "Friend list + detailed friend profile screen"
            "Block, unblock, report user flows"
            "Settings -> Blocked Users management"
            "QR code share + scan for adding friends (deep links)"
            "Friend suggestions RPC (suggest_friends migration)"
            "Realtime friend request updates"
        )
    }
    @{
        Title = "v0.5-0.6: Camera & Moments"
        Body = @(
            "Capture: gallery pick + live camera on mobile (image_picker / camera plugin)"
            "Preview screen with caption, arc-style moment details UI"
            "Audience: multi-select friends (at least one recipient required)"
            "Upload: private moments storage bucket + idempotency key per send"
            "Tables: moments, moment_recipients (delivery/seen state)"
            "Home: latest received moment (photo-first, not feed)"
            "History deck + moment detail with signed image URLs"
            "Mark seen on view; delete moment policies"
            "Realtime: MomentRealtimeSubscriber refreshes home on new moment"
        )
    }
    @{
        Title = "v0.8: Android Home Widget"
        Body = @(
            "Native: Kotlin + Jetpack Glance (MomentGlanceWidget)"
            "WidgetBridgePlugin - MethodChannel app.moment/widget"
            "Flutter AndroidWidgetBridge syncs moment image + sender to native"
            "Tap widget -> moment://moment/{id} deep link opens app"
            "Smart unread: shows newest UNREAD moment only (not a gallery)"
            "Empty state: time-of-day illustrations (morning/afternoon/night)"
            "5 sync paths: app resume, Realtime, FCM, WorkManager, native REST"
            "iOS WidgetKit: deferred (stub on iOS)"
        )
    }
    @{
        Title = "v1.1: Reactions & Pings"
        Body = @(
            "moment_reactions: one reaction per user per moment"
            "Reaction types: heart, laugh, fire, love, wow"
            "Reaction picker sheet on Home + Moment detail"
            "pings table: lightweight nudge to friend (optional moment context)"
            "Ping sender from Home or moment detail"
            "SocialRepository Clean Architecture layer"
            "Realtime enabled on reactions + pings (in-app, no push for pings yet)"
            "Push triggers for reactions added in later migrations"
        )
    }
    @{
        Title = "v1.2: Circles"
        Body = @(
            "Circle types: Us, Squad, Family, College, Custom"
            "Tables: circles, circle_members (owner + member roles)"
            "RLS: members view; owners manage membership"
            "RPC: create_circle_with_owner"
            "Circles tab: list, create sheet with type + friend picker"
            "Circle detail: members list, add/remove friends, custom avatar"
            "Circle moments page + prompt integration"
            "Moment+ gated for circle creation (client-side; dev flag bypass)"
            "Member limit enforced (migration: limit_circle_members)"
        )
    }
    @{
        Title = "v1.3: Daily Prompts"
        Body = @(
            "One global prompt per UTC day (rotating template pool)"
            "Tables: daily_prompts, prompt_responses"
            "RPC: get_todays_prompt()"
            "Home: today's prompt card -> pick circle -> camera"
            "Circle detail: prompt card -> Today page with response collage"
            "Camera prompt mode auto-selects circle members as audience"
            "Today page: collage grid, respond, save-as-memory flow"
            "Custom prompts for Moment+: listed but not yet implemented"
        )
    }
    @{
        Title = "v1.4: Memory Vault"
        Body = @(
            "Save memories from daily prompt collages and manual creation"
            "Tables: memories, memory_items, memory_participants"
            "RPC: create_memory_from_prompt_responses"
            "Memories tab: scrapbook-style vault cards (not photo grid)"
            "Memory detail: cover, stats, timeline, participants, delete"
            "Circle Today: Save as Memory -> title dialog -> vault"
            "Free tier: 3 saved memories | Moment+: unlimited"
            "Extended in v1.8 with types, themes, chapters, custom covers"
        )
    }
    @{
        Title = "v1.5: Time Travel"
        Body = @(
            "Surface moments from 1, 2, and 3 years ago (same calendar day, UTC)"
            "Privacy: only moments user sent or received"
            "RPC: get_time_travel_moments()"
            "Home: compact Time Travel teaser card"
            "Full page at /time-travel with Relive -> moment detail"
            "Currently NOT premium-gated (marketing lists Time Travel+)"
            "Deferred: multi-person / circle-filtered time travel"
        )
    }
    @{
        Title = "v1.6: Moment+ Premium"
        Body = @(
            "Product name: Moment+ | Entitlement key: moment_plus"
            "Tables: subscription_plans, subscriptions, subscription_entitlements, app_config"
            "Plans: INR 99/month, INR 699/year (remote config, not hardcoded)"
            "RPCs: get_moment_plus_offering, request_moment_plus_checkout"
            "Checkout: STUB - returns pending; no App Store / Play Billing yet"
            "Free tier: 3 saved memories; premium memory themes gated server-side"
            "Premium page: plan picker, feature list, subscribe button"
            "Grant premium: manual subscription row in DB -> sync_moment_plus_entitlement"
        )
    }
    @{
        Title = "Moment+ - What's Gated vs Free"
        Body = @(
            "SERVER-ENFORCED (hard gate):"
            "  * Widget themes, accent, typography, person/circle source (upsert_widget_preferences)"
            "  * Premium memory themes beyond minimal (create/update memory RPCs)"
            "FREE FOR ALL USERS:"
            "  * Widget privacy (full/blur/private, lock screen, per-person overrides)"
            "CLIENT-ONLY gates (soft): memory count, circles creation, circle photos"
            "MARKETING ONLY (not implemented): Custom prompts, HD archive, Time Travel+"
            "DEV FLAGS (AppFeatures): momentPlusWidgetsUnlocked, CirclesUnlocked, CirclePhotosUnlocked"
            "  -> All currently TRUE - paywalls disabled in dev builds"
        )
    }
    @{
        Title = "v1.7: Premium Widget Customization"
        Body = @(
            "Relationship themes: minimal, love, family, friends, bestie, sunset, midnight, memory, etc."
            "Accent color picker + typography options (default, serif, rounded, mono)"
            "Widget mode: Latest | Person | Circle (source selection)"
            "In-app style preview + widget reliability card"
            "Pin widget to home screen from customization page"
            "Streak badge on widget (from fire emoji in caption, not global streak)"
            "Paused widget state"
            "Settings split: Widget Settings (what appears) vs Widget Privacy (how it renders)"
            "Free users see defaults; saved_preferences restored on resubscribe"
        )
    }
    @{
        Title = "v1.8: Advanced Memories"
        Body = @(
            "Memory types: prompt, circle, anniversary, birthday, trip, custom"
            "Memory themes: minimal (free) + premium themes (glass, film, polaroid, etc.)"
            "Captions, memory dates, custom cover upload (memory-covers bucket)"
            "Moment cover picker for memory covers"
            "memory_chapters table + grouped timeline (schema ready)"
            "Create memory bottom sheet from Memory Vault"
            "Edit page: /memories/:id/edit - caption, theme, date, cover"
            "Type filters on Memory Vault tab"
            "Deferred: assigning moments to chapters from UI"
        )
    }
    @{
        Title = "Chat Module"
        Body = @(
            "Full 1:1 chat: inbox + thread with realtime messages"
            "Features: text, image messages, replies, reactions, edit, star, delete for me/everyone"
            "Typing indicators + read receipts (last seen on profiles)"
            "Inbox long-press: pin, mute, delete conversation, block/unblock"
            "chat_conversation_settings: is_pinned, is_muted, is_hidden"
            "delete_chat_conversation RPC - full message wipe (not just hide)"
            "Blocked state UI inside thread (block/unblock without leaving chat)"
            "Moment Space: shared moment timeline within chat thread"
            "Push: notify-chat Edge Function (respects mute setting)"
            "Loading UX: shimmer until initial load (no flicker)"
        )
    }
    @{
        Title = "Push Notifications"
        Body = @(
            "FCM device tokens stored in device_tokens table"
            "Edge Functions + DB triggers for push delivery:"
            "  * New moment received"
            "  * Chat message, reaction, edit"
            "  * Friend request + accepted"
            "  * Ping / reaction on moments"
            "Widget background sync via FCM when app is killed"
            "Notification settings page: per-category toggles"
            "Muted chat conversations skip push (returns skipped: muted)"
            "In-app Realtime still works when app is open (no push needed)"
        )
    }
    @{
        Title = "Home Screen & Camera UX"
        Body = @(
            "Home tab redesigned as camera-first (not a feed)"
            "Live camera viewfinder (LiveCameraHost) + shutter button"
            "Gallery + flip camera buttons (custom white PNG icons)"
            "Flash toggle chip on viewfinder"
            "Top bar: profile avatar, Friends pill, notifications bell"
            "Swipe up anywhere -> Memories overlay (SnapMemoriesView)"
            "History bottom sheet with moment deck"
            "Camera preview: arc-style moment details, delete button (no crop/edit)"
            "Realtime refresh when new moment arrives"
        )
    }
    @{
        Title = "Onboarding & Auth Flow"
        Body = @(
            "4-screen onboarding: Welcome, Share Moments, Your People, Privacy"
            "Shown only once (SharedPreferences: onboarding_complete_v1)"
            "Re-shown only after app delete / clear data"
            "Skip (top-right) + Next (bottom-right) navigation"
            "Splash -> onboarding (first launch) -> login/register"
            "Permissions setup page after first auth (camera, contacts, etc.)"
            "Login screen: new app launcher icon logo (IconKitchen assets)"
            "App icons: IconKitchen for Android res/ + iOS AppIcon.appiconset"
        )
    }
    @{
        Title = "Widget Privacy System"
        Body = @(
            "Separate from widget SOURCE (latest/person/circle) - privacy controls RENDERING"
            "Global privacy mode: Full | Blur | Private"
            "Per-sender overrides via privacy_overrides JSONB map"
            "Lock-screen privacy preference (hide content when device locked)"
            "Display toggles: show sender, timestamp, captions"
            "Paused widget state"
            "Android render pipeline: WidgetRenderResolver"
            "  Order: paused -> lock screen placeholder -> privacy mode -> unread blur"
            "Private mode: WidgetPrivateImageGuard - no image retention on device"
            "Reveal: WidgetRevealActivity (3s countdown) + unlock clear frame on device unlock"
            "Widget privacy is FREE - not Moment+ gated"
        )
    }
    @{
        Title = "Widget Sync Architecture"
        Body = @(
            "Supabase (moments, seen_at) -> Flutter (selection, read cache, prefs)"
            "  -> Method Channel -> Kotlin (queue, images, Glance UI)"
            "Sync path 1: App open / resume - HomeWidgetSyncService.sync()"
            "Sync path 2: Supabase Realtime insert - WidgetMomentStreamService"
            "Sync path 3: FCM push (app killed) - MomentFirebaseMessagingService"
            "Sync path 4: WorkManager periodic (~15 min) - WidgetBackgroundSyncWorker"
            "Sync path 5: Native REST - WidgetSupabaseSync (unseen only)"
            "Read cache: optimistic local read IDs (SharedPreferences)"
            "Queue capped at MAX_ENTRIES = 1 (single unread surface)"
        )
    }
    @{
        Title = "Deep Links"
        Body = @(
            "Scheme: moment://"
            "moment://moment/{id} - open moment detail (widget tap)"
            "moment://camera - open camera (empty widget tap)"
            "moment://widget/ping/{id} - ping from widget (routing ready)"
            "moment://friends/scan - QR friend scan"
            "DeepLinkMapper in Flutter maps URIs to GoRouter locations"
            "Android widget + FCM payloads use same deep link format"
            "QR friend links for share/add friend flow"
        )
    }
    @{
        Title = "Navigation & App Shell"
        Body = @(
            "Bottom nav: Home | Circles | Chat | Profile"
            "Memories: swipe-up overlay (not a tab)"
            "Camera: full-screen overlay route"
            "Key routes: /premium, /widget-customize, /settings/widget-privacy"
            "  /time-travel, /memories/:id/edit, /chat/:userId"
            "GoRouter redirect: unauthenticated -> login; auth on public routes -> home"
            "Deep link targets resolved before auth redirects"
            "Settings: grouped sections (Appearance, Widget, Notifications, Help, Legal)"
        )
    }
    @{
        Title = "Settings & Appearance"
        Body = @(
            "Appearance: theme mode (dark/light) + accent color (local SharedPreferences)"
            "Notification settings: per-category push toggles"
            "Widget Settings: source picker (latest/person/circle) + link to privacy"
            "Widget Privacy: auto-save (no Save button), per-person bottom sheet"
            "Blocked users, Help & FAQ, Report problem, Terms, Privacy policy"
            "Profile: edit profile, friends, home widget link, Moment+ entry"
            "Legal documents embedded in app (subscription terms included)"
        )
    }
    @{
        Title = "Supabase Database (50 Migrations)"
        Body = @(
            "Core: profiles, friendships, moments, moment_recipients"
            "Social: reactions, pings, circles, circle_members, daily_prompts"
            "Memories: memories, memory_items, memory_chapters, memory_participants"
            "Chat: conversations, messages, typing, reactions, conversation_settings"
            "Widget: widget_preferences (theme + privacy columns)"
            "Subscription: plans, subscriptions, entitlements, app_config"
            "Push: device_tokens + notify triggers"
            "Storage buckets: avatars, moments, memory-covers, circle-avatars, chat-images"
            "50 SQL migrations from 20260815120000 through 20260917100000"
        )
    }
    @{
        Title = "Security Model"
        Body = @(
            "Row Level Security (RLS) on all product tables"
            "Client uses Supabase publishable key only (service role rejected)"
            "AppEnv.validate() rejects service-role keys at startup"
            "Logger redacts token/key/secret fields"
            "Storage RLS: sender upload, recipient read via moment/friendship link"
            "Security definer RPCs for complex operations (widget prefs, memories)"
            "Account deletion via delete_own_account() RPC"
            "Function search_path hardening on auth helpers"
        )
    }
    @{
        Title = "What's Working End-to-End"
        Body = @(
            "Auth: register, login, session restore, profile edit, account delete"
            "Friends: search, request, accept, block, report, QR add"
            "Moments: capture, send, receive, view, react, ping, delete"
            "Widget: unread display, mark read, empty states, privacy modes, reveal"
            "Circles: create, members, prompts, today page, circle moments"
            "Memories: create, edit, themes, covers, vault, time travel"
            "Chat: inbox, thread, images, reactions, pin/mute/delete"
            "Push: moment, chat, friend request notifications"
            "Premium: offering page, entitlement sync, feature gates (partial)"
        )
    }
    @{
        Title = "Partially Done / Known Gaps"
        Body = @(
            "Real IAP checkout - stub only (App Store / Play Billing deferred)"
            "iOS home widget - Android only (stub bridge on iOS)"
            "Server-side memory count limit - client-only enforcement"
            "Circles premium gate - client-only (no server RPC check)"
            "Widget reaction/ping buttons on home screen - deep links only, no native UI"
            "Multi-moment widget cycling - queue capped at 1"
            "Custom prompts, HD archive - marketing copy only"
            "Video capture - placeholder (coming soon)"
            "Social sign-in - placeholder in auth chrome"
            "Chapter moment assignment UI - schema ready, UI deferred"
        )
    }
    @{
        Title = "Deferred / Not Started (2.0+)"
        Body = @(
            "Version 2.0: Scale + Intelligence (AI features) - after PMF validation"
            "AI memory summaries and smart features"
            "iOS WidgetKit implementation"
            "Real payment processors (Stripe / RevenueCat / native IAP)"
            "Entitlement admin grant UI"
            "Native Android widget instrumentation tests"
            "Integration tests for HomeWidgetSyncService + FCM path"
            "Thumbnail-only widget image pipeline (currently full images)"
        )
    }
    @{
        Title = "Release Readiness - Dev Flags"
        Body = @(
            "Before production release, set AppFeatures flags to FALSE:"
            "  momentPlusWidgetsUnlocked = false"
            "  momentPlusCirclesUnlocked = false"
            "  momentPlusCirclePhotosUnlocked = false"
            "Wire real App Store / Play Billing to request_moment_plus_checkout"
            "Add server-side memory count check in create_advanced_memory RPC"
            "Add server-side circles premium check in create_circle_with_owner"
            "Complete iOS widget or hide widget promo on iOS"
            "Run: dart format, flutter analyze, flutter test before release"
        )
    }
    @{
        Title = "Testing & Verification"
        Body = @(
            "Unit/widget tests: flutter test (subscription, widget prefs, deep links, etc.)"
            "Widget privacy tests: widget_preferences_test.dart (12 tests)"
            "Static analysis: flutter analyze"
            "Device testing required for: widget privacy, lock screen, FCM sync"
            "Full app rebuild needed for Kotlin/native/asset changes"
            "Key test files: deep_link_mapper_test, subscription_test, widget_preferences_test"
            "No Kotlin instrumentation tests yet for Android widget"
        )
    }
    @{
        Title = "User Journey - Moment to Widget"
        Body = @(
            "Flow A: Friend sends moment -> widget shows with dot prefix on sender name"
            "Flow B: User opens moment in app -> marks read -> widget clears or shows next unread"
            "Flow C: All caught up -> time-of-day empty image -> tap opens camera"
            "Flow D: Privacy full mode -> blurred on widget -> Reveal chip -> 3s full photo"
            "Flow E: Home camera -> capture -> select friends -> send -> appears in friend widget"
            "Flow F: Daily prompt -> pick circle -> respond with moment -> save as memory"
            "Flow G: Chat thread -> send image -> react -> pin conversation in inbox"
        )
    }
    @{
        Title = "Project Structure"
        Body = @(
            "lib/features/ - 12+ feature modules (auth, friends, circles, moments, memories, chat, etc.)"
            "lib/core/widget/ - home widget sync, read cache, moment selector, bridge"
            "android/.../widget/ - Glance UI, render resolver, privacy, bitmap, sync"
            "supabase/migrations/ - 50 SQL migration files"
            "supabase/functions/ - notify-chat, notify-moment Edge Functions"
            "docs/ - VERSION_*.md per release + ARCHITECTURE.md + E2E status HTML"
            "assets/images/ - onboarding, widget empty states, icons, premium art"
            "test/ - unit tests mirroring feature structure"
        )
    }
    @{
        Title = "Thank You"
        Body = @(
            "Moment - Private Social-Memory Application"
            "Version 1.8.1 | Complete Documentation"
            "Flutter + Supabase + Android Glance Widget"
            "For questions: see docs/ folder in repository"
            "  ARCHITECTURE.md | MOMENT_IMPLEMENTATION_STATUS.md"
            "  moment-e2e-status.html | feature-implementation-e2e.html"
        )
    }
)

try {
    $ppt = New-Object -ComObject PowerPoint.Application
    $ppt.Visible = [Microsoft.Office.Core.MsoTriState]::msoTrue

    if (Test-Path $outputPath) {
        Remove-Item $outputPath -Force
    }

    $pres = $ppt.Presentations.Add()

    # Apply dark-friendly colors via theme is complex; set default font on master
    foreach ($slideData in $slides) {
        $layout = if ($slideData.Layout) { $slideData.Layout } else { 2 }
        $slide = $pres.Slides.Add($pres.Slides.Count + 1, $layout)

        # Title
        if ($slide.Shapes.HasTitle -eq -1) {
            $slide.Shapes.Title.TextFrame.TextRange.Text = $slideData.Title
            $slide.Shapes.Title.TextFrame.TextRange.Font.Name = "Segoe UI"
            $slide.Shapes.Title.TextFrame.TextRange.Font.Size = 32
            $slide.Shapes.Title.TextFrame.TextRange.Font.Bold = $true
        }

        # Body
        $bodyText = if ($slideData.Body -is [array]) {
            ($slideData.Body | ForEach-Object { "* $_" }) -join "`r"
        } else {
            $slideData.Body
        }

        if ($layout -eq 1) {
            if ($slide.Shapes.Placeholders.Count -ge 2) {
                $body = $slide.Shapes.Placeholders.Item(2).TextFrame.TextRange
                $body.Text = $bodyText
                $body.Font.Name = "Segoe UI"
                $body.Font.Size = 18
            }
        } elseif ($slide.Shapes.Placeholders.Count -ge 2) {
            $body = $slide.Shapes.Placeholders.Item(2).TextFrame.TextRange
            $body.Text = $bodyText
            $body.Font.Name = "Segoe UI"
            $body.Font.Size = 16
            $body.ParagraphFormat.SpaceAfter = 6
        }
    }

    $pres.SaveAs($outputPath)
    $pres.Close()
    $ppt.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($pres) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ppt) | Out-Null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()

    Write-Output "SUCCESS: $outputPath"
    Write-Output "Slides: $($slides.Count)"
} catch {
    Write-Error "Failed to generate PPT: $($_.Exception.Message)"
    exit 1
}
