import 'package:moment/core/config/app_env.dart';
import 'package:moment/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseBootstrap {
  Future<void> initialize(AppEnv env);
}

class LiveSupabaseBootstrap implements SupabaseBootstrap {
  const LiveSupabaseBootstrap({required this.logger});

  final AppLogger logger;

  @override
  Future<void> initialize(AppEnv env) async {
    // PKCE is the supabase_flutter default auth flow.
    await Supabase.initialize(
      url: env.supabaseUrl,
      publishableKey: env.supabasePublishableKey,
    );
    logger.info(
      'Supabase initialized',
      context: {'environment': env.environmentName},
    );
  }
}

class NoOpSupabaseBootstrap implements SupabaseBootstrap {
  const NoOpSupabaseBootstrap({required this.logger});

  final AppLogger logger;

  @override
  Future<void> initialize(AppEnv env) async {
    logger.info('Supabase bootstrap skipped (test/no-op).');
  }
}
