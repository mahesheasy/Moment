import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/lifecycle/session_cubit.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/app/router/go_router_refresh.dart';
import 'package:moment/app/shell/main_shell.dart';
import 'package:moment/features/friends/presentation/pages/friend_profile_page.dart';
import 'package:moment/features/friends/presentation/pages/friend_qr_scan_page.dart';
import 'package:moment/features/friends/presentation/pages/friends_page.dart';
import 'package:moment/features/auth/presentation/pages/login_page.dart';
import 'package:moment/features/auth/presentation/pages/permissions_setup_page.dart';
import 'package:moment/features/auth/presentation/pages/onboarding_page.dart';
import 'package:moment/features/auth/presentation/pages/splash_page.dart';
import 'package:moment/features/circles/presentation/pages/circle_detail_page.dart';
import 'package:moment/features/circles/presentation/pages/circle_moments_page.dart';
import 'package:moment/features/circles/presentation/pages/circles_page.dart';
import 'package:moment/features/memories/presentation/pages/memory_detail_page.dart';
import 'package:moment/features/memories/presentation/pages/memory_edit_page.dart';
import 'package:moment/features/chat/presentation/pages/chat_inbox_page.dart';
import 'package:moment/features/chat/presentation/pages/chat_thread_page.dart';
import 'package:moment/features/moments/presentation/pages/camera_placeholder_page.dart';
import 'package:moment/features/moments/presentation/pages/home_page.dart';
import 'package:moment/features/moments/presentation/pages/moment_detail_page.dart';
import 'package:moment/features/prompts/domain/entities/camera_prompt_context.dart';
import 'package:moment/features/prompts/presentation/cubit/prompt_cubit.dart';
import 'package:moment/features/prompts/presentation/pages/circle_today_page.dart';
import 'package:moment/features/time_travel/presentation/pages/time_travel_page.dart';
import 'package:moment/features/subscription/presentation/pages/premium_page.dart';
import 'package:moment/features/widget_preferences/presentation/pages/widget_customization_page.dart';
import 'package:moment/features/widget_preferences/presentation/pages/widget_privacy_page.dart';
import 'package:moment/features/widget_preferences/presentation/pages/widget_settings_page.dart';
import 'package:moment/features/profile/presentation/pages/profile_page.dart';
import 'package:moment/features/settings/presentation/pages/appearance_settings_page.dart';
import 'package:moment/features/settings/presentation/pages/blocked_users_page.dart';
import 'package:moment/features/settings/domain/legal_documents.dart';
import 'package:moment/features/settings/presentation/pages/help_page.dart';
import 'package:moment/features/settings/presentation/pages/legal_document_page.dart';
import 'package:moment/features/settings/presentation/pages/notification_settings_page.dart';
import 'package:moment/features/settings/presentation/pages/notifications_page.dart';
import 'package:moment/features/settings/presentation/pages/report_problem_page.dart';
import 'package:moment/features/settings/presentation/pages/settings_page.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/features/auth/data/datasources/setup_preferences_local_cache.dart';
import 'package:moment/core/constants/app_constants.dart';
import 'package:moment/core/deep_links/deep_link_mapper.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

GoRouter createAppRouter({
  required SessionCubit sessionCubit,
  required DeepLinkMapper deepLinkMapper,
  String initialLocation = AppRoutes.splash,
}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  bool isPublicRoute(String location) {
    return location == AppRoutes.splash ||
        location == AppRoutes.onboarding ||
        location == AppRoutes.login ||
        location == AppRoutes.register ||
        location == AppRoutes.termsOfService ||
        location == AppRoutes.privacyPolicy;
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: GoRouterRefresh(sessionCubit.stream),
    redirect: (context, state) {
      final status = sessionCubit.state.status;
      final uri = state.uri;
      final deepLinkTarget =
          uri.scheme == AppConstants.deepLinkScheme
              ? deepLinkMapper.locationFromUri(uri)
              : null;
      final location = deepLinkTarget ?? state.matchedLocation;

      if (status == SessionStatus.unknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (status == SessionStatus.unauthenticated && !isPublicRoute(location)) {
        return AppRoutes.login;
      }

      if (status == SessionStatus.authenticated) {
        final setupComplete =
            sl<SetupPreferencesLocalCache>().isPermissionsSetupCompleteSync;

        if (deepLinkTarget != null && deepLinkTarget != state.matchedLocation) {
          return deepLinkTarget;
        }

        if (!setupComplete && location != AppRoutes.setupPermissions) {
          return AppRoutes.setupPermissions;
        }

        if (setupComplete && location == AppRoutes.setupPermissions) {
          return AppRoutes.home;
        }

        if (location == AppRoutes.login ||
            location == AppRoutes.register ||
            location == AppRoutes.splash ||
            location == AppRoutes.onboarding) {
          return setupComplete ? AppRoutes.home : AppRoutes.setupPermissions;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.setupPermissions,
        builder: (context, state) => const PermissionsSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      // Auth legal docs — reachable from login, register, and settings.
      GoRoute(
        path: AppRoutes.termsOfService,
        builder: (context, state) =>
            const LegalDocumentPage(type: LegalDocumentType.terms),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) =>
            const LegalDocumentPage(type: LegalDocumentType.privacy),
      ),
      GoRoute(
        path: AppRoutes.camera,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final circleId = state.uri.queryParameters['circleId'];
          final promptId = state.uri.queryParameters['promptId'];
          final promptContext = circleId != null
              ? CameraPromptContext(
                  circleId: circleId,
                  promptId: promptId,
                )
              : null;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: CameraPlaceholderPage(promptContext: promptContext),
            transitionsBuilder: (context, animation, secondary, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.timeTravel,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TimeTravelPage(),
      ),
      GoRoute(
        path: '/moment/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            MomentDetailPage(momentId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/circles/:id/moments',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            CircleMomentsPage(circleId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/circles/:id/today',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            CircleTodayPage(circleId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/circles/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            CircleDetailPage(circleId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/memories/:id/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            MemoryEditPage(memoryId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/memories/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: MemoryDetailPage(
              memoryId: state.pathParameters['id'] ?? '',
            ),
            transitionsBuilder: (context, animation, secondary, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.friends,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FriendsPage(),
      ),
      GoRoute(
        path: AppRoutes.friendsScan,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FriendQrScanPage(),
      ),
      GoRoute(
        path: '/chat/:userId',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          final otherUser = state.extra;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: ChatThreadPage(
              userId: userId,
              otherUser: otherUser is UserProfile ? otherUser : null,
            ),
            transitionDuration: const Duration(milliseconds: 320),
            reverseTransitionDuration: const Duration(milliseconds: 260),
            transitionsBuilder: (context, animation, secondary, child) {
              final curve = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curve),
                child: FadeTransition(opacity: curve, child: child),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/friends/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            FriendProfilePage(userId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.blockedUsers,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BlockedUsersPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => createNotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.appearance,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AppearanceSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.help,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const HelpPage(),
      ),
      GoRoute(
        path: AppRoutes.reportProblem,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ReportProblemPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ProfileEditPage(),
      ),
      GoRoute(
        path: AppRoutes.premium,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PremiumPage(),
      ),
      GoRoute(
        path: AppRoutes.widgetCustomize,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WidgetCustomizationPage(),
      ),
      GoRoute(
        path: AppRoutes.widgetSettings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WidgetSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.widgetPrivacy,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WidgetPrivacyPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.circles,
                builder: (context, state) => const CirclesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (context, state) => const ChatInboxPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
