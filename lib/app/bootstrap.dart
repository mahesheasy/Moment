import 'package:flutter/widgets.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/moment_app.dart';
import 'package:moment/core/config/app_env.dart';
import 'package:moment/core/firebase/firebase_bootstrap.dart';
import 'package:moment/core/logging/app_logger.dart';
import 'package:moment/core/supabase/supabase_bootstrap.dart';

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

  runApp(MomentApp(router: sl()));
}
