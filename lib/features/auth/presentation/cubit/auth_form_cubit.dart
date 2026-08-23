import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:moment/features/auth/domain/usecases/auth_usecases.dart';

enum AuthFormStatus { initial, loading, success, failure, emailSent }

class LoginState extends Equatable {
  const LoginState({
    this.status = AuthFormStatus.initial,
    this.errorMessage,
    this.infoMessage,
  });

  final AuthFormStatus status;
  final String? errorMessage;
  final String? infoMessage;

  @override
  List<Object?> get props => [status, errorMessage, infoMessage];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._login, this._resetPassword) : super(const LoginState());

  final LoginUseCase _login;
  final ResetPasswordUseCase _resetPassword;

  Future<void> submit({required String email, required String password}) async {
    emit(const LoginState(status: AuthFormStatus.loading));
    final result = await _login(email: email, password: password);
    result.when(
      success: (_) => emit(const LoginState(status: AuthFormStatus.success)),
      failure: (failure) => emit(
        LoginState(
          status: AuthFormStatus.failure,
          errorMessage: failure.message,
        ),
      ),
    );
  }

  Future<void> sendPasswordReset(String email) async {
    emit(const LoginState(status: AuthFormStatus.loading));
    final result = await _resetPassword(email);
    result.when(
      success: (_) => emit(
        const LoginState(
          status: AuthFormStatus.emailSent,
          infoMessage: 'Password reset link sent. Check your email.',
        ),
      ),
      failure: (failure) => emit(
        LoginState(
          status: AuthFormStatus.failure,
          errorMessage: failure.message,
        ),
      ),
    );
  }
}

class RegisterState extends Equatable {
  const RegisterState({
    this.status = AuthFormStatus.initial,
    this.errorMessage,
    this.infoMessage,
  });

  final AuthFormStatus status;
  final String? errorMessage;
  final String? infoMessage;

  @override
  List<Object?> get props => [status, errorMessage, infoMessage];
}

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this._register) : super(const RegisterState());

  final RegisterUseCase _register;

  Future<void> submit({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    emit(const RegisterState(status: AuthFormStatus.loading));
    final result = await _register(
      RegisterParams(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      ),
    );
    result.when(
      success: (outcome) {
        if (outcome.emailConfirmationRequired) {
          emit(
            const RegisterState(
              status: AuthFormStatus.emailSent,
              infoMessage:
                  'Confirm your email, then sign in to start using Moment.',
            ),
          );
          return;
        }
        emit(const RegisterState(status: AuthFormStatus.success));
      },
      failure: (failure) => emit(
        RegisterState(
          status: AuthFormStatus.failure,
          errorMessage: failure.message,
        ),
      ),
    );
  }
}
