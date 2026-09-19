import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/lifecycle/session_cubit.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/constants/app_constants.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_durations.dart';
import 'package:moment/features/auth/data/datasources/onboarding_preferences_local_cache.dart';
import 'package:moment/features/auth/data/datasources/setup_preferences_local_cache.dart';
import 'package:moment/core/widget/home_widget_sync_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: AppDurations.emphasis)
      ..forward();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(AppConstants.splashHold);
    if (!mounted) return;

    await context.read<SessionCubit>().restore();
    if (!mounted) return;

    final authed = context.read<SessionCubit>().state.isAuthenticated;
    if (authed) {
      unawaited(sl<HomeWidgetSyncService>().sync(promoteLatest: true));
      context.go(
        await sl<SetupPreferencesLocalCache>().isPermissionsSetupComplete()
            ? AppRoutes.home
            : AppRoutes.setupPermissions,
      );
      return;
    }

    final onboardingDone = await sl<OnboardingPreferencesLocalCache>().isComplete();
    if (!mounted) return;
    context.go(onboardingDone ? AppRoutes.login : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _fade, curve: AppDurations.easeOut),
          child: Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w400,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
