import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moment/app/lifecycle/app_lifecycle_cubit.dart';
import 'package:moment/app/lifecycle/session_cubit.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository authRepository;

  setUp(() {
    authRepository = _MockAuthRepository();
    when(
      () => authRepository.authStateChanges,
    ).thenAnswer((_) => const Stream<bool>.empty());
  });

  group('SessionCubit', () {
    blocTest<SessionCubit, SessionState>(
      'restore emits authenticated when session exists',
      build: () {
        when(() => authRepository.restoreSession()).thenAnswer(
          (_) async => const Success(
            AuthSession(userId: 'user-1', email: 'test@example.com'),
          ),
        );
        return SessionCubit(authRepository: authRepository);
      },
      act: (cubit) => cubit.restore(),
      expect: () => [const SessionState(status: SessionStatus.authenticated)],
    );

    blocTest<SessionCubit, SessionState>(
      'restore emits unauthenticated when session is missing',
      build: () {
        when(
          () => authRepository.restoreSession(),
        ).thenAnswer((_) async => const Success(null));
        return SessionCubit(authRepository: authRepository);
      },
      act: (cubit) => cubit.restore(),
      expect: () => [const SessionState(status: SessionStatus.unauthenticated)],
    );
  });

  group('AppLifecycleCubit', () {
    blocTest<AppLifecycleCubit, AppLifecycleStateView>(
      'tracks paused and resumed states',
      build: AppLifecycleCubit.new,
      act: (cubit) {
        cubit.handle(AppLifecycleState.paused);
        cubit.handle(AppLifecycleState.resumed);
      },
      expect: () => const [
        AppLifecycleStateView(AppLifecycleState.paused),
        AppLifecycleStateView(AppLifecycleState.resumed),
      ],
    );
  });
}
