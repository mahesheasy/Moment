import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';

enum SessionStatus { unknown, unauthenticated, authenticated }

class SessionState extends Equatable {
  const SessionState({required this.status});

  const SessionState.unknown() : status = SessionStatus.unknown;

  final SessionStatus status;

  bool get isAuthenticated => status == SessionStatus.authenticated;

  @override
  List<Object?> get props => [status];
}

class SessionCubit extends Cubit<SessionState> {
  SessionCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const SessionState.unknown()) {
    _subscription = _authRepository.authStateChanges.listen((isSignedIn) {
      emit(
        SessionState(
          status: isSignedIn
              ? SessionStatus.authenticated
              : SessionStatus.unauthenticated,
        ),
      );
    });
  }

  final AuthRepository _authRepository;
  late final StreamSubscription<bool> _subscription;

  Future<void> restore() async {
    final result = await _authRepository.restoreSession();
    final session = result.valueOrNull;
    emit(
      SessionState(
        status: session != null
            ? SessionStatus.authenticated
            : SessionStatus.unauthenticated,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
