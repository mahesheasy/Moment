import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/lifecycle/session_cubit.dart';
import 'package:moment/app/moment_app.dart';
import 'package:moment/app/router/app_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/config/app_env.dart';
import 'package:moment/core/constants/app_constants.dart';
import 'package:moment/core/deep_links/deep_link_mapper.dart';
import 'package:moment/core/firebase/firebase_bootstrap.dart';
import 'package:moment/core/logging/app_logger.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/core/supabase/supabase_bootstrap.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository authRepository;

  const env = AppEnv(
    supabaseUrl: 'https://example.supabase.co',
    supabasePublishableKey: 'sb_publishable_test',
    environmentName: 'test',
  );

  setUp(() async {
    authRepository = _MockAuthRepository();
    when(
      () => authRepository.authStateChanges,
    ).thenAnswer((_) => const Stream<bool>.empty());
    when(
      () => authRepository.restoreSession(),
    ).thenAnswer((_) async => const Success(null));
    when(() => authRepository.currentUserId).thenReturn(null);

    const logger = AppLogger();
    await configureDependencies(
      env: env,
      supabaseBootstrap: const NoOpSupabaseBootstrap(logger: logger),
      firebaseBootstrap: const NoOpFirebaseBootstrap(logger: logger),
      authRepository: authRepository,
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('splash shows Moment then opens onboarding when logged out', (
    tester,
  ) async {
    await tester.pumpWidget(MomentApp(router: sl()));
    expect(find.text(AppConstants.appName), findsOneWidget);

    await tester.pump(AppConstants.splashHold);
    await tester.pumpAndSettle();

    expect(find.text('Capture'), findsOneWidget);
    expect(find.text('every moment'), findsOneWidget);
  });

  testWidgets('unauthenticated users are redirected to login from home', (
    tester,
  ) async {
    final sessionCubit = sl<SessionCubit>();
    await sessionCubit.restore();
    final router = createAppRouter(
      sessionCubit: sessionCubit,
      deepLinkMapper: const DeepLinkMapper(),
      initialLocation: AppRoutes.home,
    );

    await tester.pumpWidget(MomentApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back.'), findsOneWidget);
  });

  testWidgets('login page renders sign in form', (tester) async {
    final sessionCubit = sl<SessionCubit>();
    await sessionCubit.restore();
    final router = createAppRouter(
      sessionCubit: sessionCubit,
      deepLinkMapper: const DeepLinkMapper(),
      initialLocation: AppRoutes.login,
    );

    await tester.pumpWidget(MomentApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
