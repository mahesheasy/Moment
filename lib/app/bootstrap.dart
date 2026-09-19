import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/lifecycle/session_cubit.dart';
import 'package:moment/app/moment_app.dart';
import 'package:moment/core/config/app_env.dart';
import 'package:moment/core/firebase/firebase_bootstrap.dart';
import 'package:moment/core/logging/app_logger.dart';
import 'package:moment/core/presence/profile_presence_service.dart';
import 'package:moment/core/supabase/supabase_bootstrap.dart';
import 'package:moment/features/auth/data/datasources/onboarding_preferences_local_cache.dart';
import 'package:moment/features/auth/data/datasources/setup_preferences_local_cache.dart';

Future<void> bootstrap({
  AppEnv? env,
  SupabaseBootstrap? supabaseBootstrap,
  FirebaseBootstrap? firebaseBootstrap,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final resolvedEnv = env ?? await EnvLoader.load();
  resolvedEnv.validate();

  const logger = AppLogger();
  await configureDependencies(
    env: resolvedEnv,
    supabaseBootstrap:
        supabaseBootstrap ?? const LiveSupabaseBootstrap(logger: logger),
    firebaseBootstrap:
        firebaseBootstrap ?? const NoOpFirebaseBootstrap(logger: logger),
  );

  await sl<SupabaseBootstrap>().initialize(resolvedEnv);
  await sl<FirebaseBootstrap>().initialize();
  await sl<SetupPreferencesLocalCache>().load();
  await sl<OnboardingPreferencesLocalCache>().load();
  await sl<SessionCubit>().restore();
  if (sl<SessionCubit>().state.isAuthenticated) {
    sl<ProfilePresenceService>().start();
    unawaited(sl<ProfilePresenceService>().pulse());
  }

  runApp(MomentApp(router: sl()));
}
