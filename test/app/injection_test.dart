import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/lifecycle/app_lifecycle_cubit.dart';
import 'package:moment/app/lifecycle/session_cubit.dart';
import 'package:moment/core/config/app_env.dart';
import 'package:moment/core/firebase/firebase_bootstrap.dart';
import 'package:moment/core/logging/app_logger.dart';
import 'package:moment/core/supabase/supabase_bootstrap.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('registers foundation dependencies', () async {
    final authRepository = _MockAuthRepository();
    when(
      () => authRepository.authStateChanges,
    ).thenAnswer((_) => const Stream<bool>.empty());

    const logger = AppLogger();
    await configureDependencies(
      env: const AppEnv(
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'sb_publishable_test',
        environmentName: 'test',
      ),
      supabaseBootstrap: const NoOpSupabaseBootstrap(logger: logger),
      firebaseBootstrap: const NoOpFirebaseBootstrap(logger: logger),
      authRepository: authRepository,
    );

    expect(sl<AppEnv>().environmentName, 'test');
    expect(sl<SessionCubit>(), isA<SessionCubit>());
    expect(sl<AppLifecycleCubit>(), isA<AppLifecycleCubit>());
    expect(sl<GoRouter>(), isA<GoRouter>());
    expect(sl<AuthRepository>(), authRepository);

    await sl.reset();
    expect(GetIt.instance.isRegistered<AppEnv>(), isFalse);
  });
}
