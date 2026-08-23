import 'package:moment/core/errors/failures.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:moment/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client, this._profiles);

  final SupabaseClient _client;
  final ProfileRemoteDataSource _profiles;

  Stream<bool> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session != null);

  AuthSession? get currentSession {
    final session = _client.auth.currentSession;
    final user = session?.user;
    if (user == null) return null;
    return AuthSession(userId: user.id, email: user.email ?? '');
  }

  Future<AuthSession?> restoreSession() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      return AuthSession(
        userId: session.user.id,
        email: session.user.email ?? '',
      );
    }

    try {
      final response = await _client.auth.refreshSession();
      final refreshed = response.session;
      if (refreshed == null) return null;
      return AuthSession(
        userId: refreshed.user.id,
        email: refreshed.user.email ?? '',
      );
    } on AuthException {
      return null;
    }
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthenticationFailure(message: 'Sign in failed.');
    }
    return AuthSession(userId: user.id, email: user.email ?? email);
  }

  Future<RegisterResult> register(RegisterParams params) async {
    final response = await _client.auth.signUp(
      email: params.email,
      password: params.password,
      data: {'username': params.username, 'display_name': params.displayName},
    );
    final user = response.user;
    if (user == null) {
      throw const AuthenticationFailure(message: 'Could not create account.');
    }

    var session = response.session ?? _client.auth.currentSession;
    if (session == null) {
      try {
        final loginResponse = await _client.auth.signInWithPassword(
          email: params.email,
          password: params.password,
        );
        session = loginResponse.session ?? _client.auth.currentSession;
      } on AuthException {
        session = null;
      }
    }

    if (session == null) {
      return const RegisterResult(emailConfirmationRequired: true);
    }

    return RegisterResult(
      session: AuthSession(userId: user.id, email: user.email ?? params.email),
    );
  }

  Future<void> logout() => _client.auth.signOut();

  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<void> deleteAccount() async {
    await _client.rpc<void>('delete_own_account');
    await _client.auth.signOut();
  }

  Failure mapAuthError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        return const AuthenticationFailure(
          message: 'Email or password is incorrect.',
        );
      }
      if (message.contains('already registered')) {
        return const ValidationFailure(
          message: 'An account with this email already exists.',
        );
      }
      if (message.contains('email not confirmed')) {
        return const AuthenticationFailure(
          message: 'Email verification is disabled — try signing in again.',
        );
      }
      return AuthenticationFailure(message: error.message, cause: error);
    }
    return _profiles.mapPostgrestError(error);
  }

  String? get currentUserId => _client.auth.currentUser?.id;
}
