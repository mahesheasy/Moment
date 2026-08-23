import 'package:equatable/equatable.dart';
import 'package:moment/core/result/result.dart';

class AuthSession extends Equatable {
  const AuthSession({required this.userId, required this.email});

  final String userId;
  final String email;

  @override
  List<Object?> get props => [userId, email];
}

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.email,
    required this.password,
    required this.username,
    required this.displayName,
  });

  final String email;
  final String password;
  final String username;
  final String displayName;

  @override
  List<Object?> get props => [email, password, username, displayName];
}

class RegisterResult extends Equatable {
  const RegisterResult({this.session, this.emailConfirmationRequired = false});

  final AuthSession? session;
  final bool emailConfirmationRequired;

  @override
  List<Object?> get props => [session, emailConfirmationRequired];
}

abstract class AuthRepository {
  Stream<bool> get authStateChanges;

  Future<Result<AuthSession?>> restoreSession();

  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });

  Future<Result<RegisterResult>> register(RegisterParams params);

  Future<Result<void>> logout();

  Future<Result<void>> resetPassword(String email);

  Future<Result<void>> deleteAccount();

  String? get currentUserId;
}
