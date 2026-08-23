import 'package:moment/core/errors/failures.dart';

class AuthValidators {
  const AuthValidators._();

  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9_]{3,30}$');

  static Failure? validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return const ValidationFailure(message: 'Email is required.');
    }
    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      return const ValidationFailure(message: 'Enter a valid email.');
    }
    return null;
  }

  static Failure? validatePassword(String password) {
    if (password.isEmpty) {
      return const ValidationFailure(message: 'Password is required.');
    }
    if (password.length < 8) {
      return const ValidationFailure(
        message: 'Password must be at least 8 characters.',
      );
    }
    return null;
  }

  static Failure? validateUsername(String username) {
    final normalized = username.trim().toLowerCase();
    if (!_usernamePattern.hasMatch(normalized)) {
      return const ValidationFailure(
        message:
            'Username must be 3–30 characters: lowercase letters, numbers, underscore.',
      );
    }
    return null;
  }

  static Failure? validateDisplayName(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return const ValidationFailure(message: 'Display name is required.');
    }
    if (trimmed.length > 80) {
      return const ValidationFailure(message: 'Display name is too long.');
    }
    return null;
  }

  static String normalizeUsername(String username) =>
      username.trim().toLowerCase();

  static String? emailField(String? value) => validateEmail(value ?? '')?.message;

  static String? passwordField(String? value) =>
      validatePassword(value ?? '')?.message;

  static String? usernameField(String? value) =>
      validateUsername(value ?? '')?.message;

  static String? displayNameField(String? value) =>
      validateDisplayName(value ?? '')?.message;
}
