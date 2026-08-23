import 'package:moment/core/errors/exception_mapper.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:moment/features/auth/domain/validators/auth_validators.dart';

class LoginUseCase {
  const LoginUseCase(this._repository, this._mapper);

  final AuthRepository _repository;
  final ExceptionMapper _mapper;

  Future<Result<AuthSession>> call({
    required String email,
    required String password,
  }) async {
    final emailError = AuthValidators.validateEmail(email);
    if (emailError != null) return Failed(emailError);
    final passwordError = AuthValidators.validatePassword(password);
    if (passwordError != null) return Failed(passwordError);

    try {
      return await _repository.login(email: email.trim(), password: password);
    } on Object catch (error, stackTrace) {
      return Failed(_mapper.map(error, stackTrace));
    }
  }
}

class RegisterUseCase {
  const RegisterUseCase(this._repository, this._mapper);

  final AuthRepository _repository;
  final ExceptionMapper _mapper;

  Future<Result<RegisterResult>> call(RegisterParams params) async {
    final emailError = AuthValidators.validateEmail(params.email);
    if (emailError != null) return Failed(emailError);
    final passwordError = AuthValidators.validatePassword(params.password);
    if (passwordError != null) return Failed(passwordError);
    final usernameError = AuthValidators.validateUsername(params.username);
    if (usernameError != null) return Failed(usernameError);
    final nameError = AuthValidators.validateDisplayName(params.displayName);
    if (nameError != null) return Failed(nameError);

    try {
      return await _repository.register(
        RegisterParams(
          email: params.email.trim(),
          password: params.password,
          username: AuthValidators.normalizeUsername(params.username),
          displayName: params.displayName.trim(),
        ),
      );
    } on Object catch (error, stackTrace) {
      return Failed(_mapper.map(error, stackTrace));
    }
  }
}

class LogoutUseCase {
  const LogoutUseCase(this._repository, this._mapper);

  final AuthRepository _repository;
  final ExceptionMapper _mapper;

  Future<Result<void>> call() async {
    try {
      return await _repository.logout();
    } on Object catch (error, stackTrace) {
      return Failed(_mapper.map(error, stackTrace));
    }
  }
}

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession?>> call() => _repository.restoreSession();
}

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository, this._mapper);

  final AuthRepository _repository;
  final ExceptionMapper _mapper;

  Future<Result<void>> call(String email) async {
    final emailError = AuthValidators.validateEmail(email);
    if (emailError != null) return Failed(emailError);

    try {
      return await _repository.resetPassword(email.trim());
    } on Object catch (error, stackTrace) {
      return Failed(_mapper.map(error, stackTrace));
    }
  }
}

class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._repository, this._mapper);

  final AuthRepository _repository;
  final ExceptionMapper _mapper;

  Future<Result<void>> call() async {
    try {
      return await _repository.deleteAccount();
    } on Object catch (error, stackTrace) {
      return Failed(_mapper.map(error, stackTrace));
    }
  }
}
