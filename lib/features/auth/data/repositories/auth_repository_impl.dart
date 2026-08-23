import 'package:moment/core/errors/exception_mapper.dart';
import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._mapper);

  final AuthRemoteDataSource _remote;
  final ExceptionMapper _mapper;

  @override
  Stream<bool> get authStateChanges => _remote.authStateChanges;

  @override
  String? get currentUserId => _remote.currentUserId;

  @override
  Future<Result<AuthSession?>> restoreSession() async {
    try {
      return Success(await _remote.restoreSession());
    } on Object catch (error, stackTrace) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapAuthError(error));
    }
  }

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      return Success(await _remote.login(email: email, password: password));
    } on Object catch (error, stackTrace) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapAuthError(error));
    }
  }

  @override
  Future<Result<RegisterResult>> register(RegisterParams params) async {
    try {
      return Success(await _remote.register(params));
    } on Object catch (error, stackTrace) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapAuthError(error));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remote.logout();
      return const Success(null);
    } on Object catch (error, stackTrace) {
      return Failed(_mapper.map(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _remote.resetPassword(email);
      return const Success(null);
    } on Object catch (error, stackTrace) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapAuthError(error));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _remote.deleteAccount();
      return const Success(null);
    } on Object catch (error, stackTrace) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapAuthError(error));
    }
  }
}
