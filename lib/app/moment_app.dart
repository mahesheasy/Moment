import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/lifecycle/app_lifecycle_cubit.dart';
import 'package:moment/app/lifecycle/session_cubit.dart';
import 'package:moment/core/constants/app_constants.dart';
import 'package:moment/core/push/push_bridge.dart';
import 'package:moment/core/push/push_registration_service.dart';
import 'package:moment/core/realtime/moment_realtime_subscriber.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_theme.dart';
import 'package:moment/core/theme/moment_colors.dart';
import 'package:moment/core/widget/home_widget_sync_service.dart';
import 'package:moment/features/settings/data/datasources/notification_preferences_local_cache.dart';
import 'package:moment/features/settings/presentation/cubit/appearance_cubit.dart';

class MomentApp extends StatefulWidget {
  const MomentApp({required this.router, super.key});

  final GoRouter router;

  @override
  State<MomentApp> createState() => _MomentAppState();
}

class _MomentAppState extends State<MomentApp> {
  late final AppLifecycleObserver _lifecycleObserver;
  StreamSubscription<AppLifecycleStateView>? _lifecycleSubscription;
  StreamSubscription<SessionState>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = AppLifecycleObserver(sl<AppLifecycleCubit>());
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _lifecycleSubscription = sl<AppLifecycleCubit>().stream.listen((state) {
      if (state.status == AppLifecycleState.resumed) {
        unawaited(sl<HomeWidgetSyncService>().sync());
        if (sl<SessionCubit>().state.isAuthenticated) {
          unawaited(sl<PushRegistrationService>().register());
        }
      }
    });
    _sessionSubscription = sl<SessionCubit>().stream.listen((state) {
      if (state.isAuthenticated) {
        unawaited(sl<PushRegistrationService>().register());
        unawaited(_syncNotificationPreferences());
        sl<MomentRealtimeSubscriber>().listen(() {
          unawaited(sl<HomeWidgetSyncService>().sync());
        });
      } else {
        sl<MomentRealtimeSubscriber>().dispose();
      }
    });
    final session = sl<SessionCubit>().state;
    if (session.isAuthenticated) {
      unawaited(sl<PushRegistrationService>().register());
      unawaited(_syncNotificationPreferences());
      sl<MomentRealtimeSubscriber>().listen(() {
        unawaited(sl<HomeWidgetSyncService>().sync());
      });
    }
  }

  Future<void> _syncNotificationPreferences() async {
    final preferences = await sl<NotificationPreferencesLocalCache>().load();
    await sl<PushBridge>().syncNotificationPreferences(preferences);
  }

  @override
  void dispose() {
    unawaited(_lifecycleSubscription?.cancel());
    unawaited(_sessionSubscription?.cancel());
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AppLifecycleCubit>()),
        BlocProvider.value(value: sl<SessionCubit>()),
        BlocProvider.value(value: sl<AppearanceCubit>()),
      ],
      child: BlocBuilder<AppearanceCubit, AppearanceState>(
        builder: (context, appearance) {
          final accent = appearance.accentColor;
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(accent: accent),
            darkTheme: AppTheme.dark(accent: accent),
            themeMode: appearance.themeMode,
            builder: (context, child) {
              final colors = Theme.of(context).extension<MomentColors>();
              if (colors != null) AppColors.bind(colors);
              return child ?? const SizedBox.shrink();
            },
            routerConfig: widget.router,
          );
        },
      ),
    );
  }
}
