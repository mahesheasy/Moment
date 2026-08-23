import 'package:moment/core/errors/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Failure mapPostgrestError(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is PostgrestException) {
    final message = _readablePostgrestMessage(error, fallback: fallback);

    if (error.code == '23505') {
      return ValidationFailure(message: message, cause: error);
    }
    if (error.code == '42501' || error.code == 'PGRST301') {
      return AuthorizationFailure(message: message, cause: error);
    }
    if (message.toLowerCase().contains('not authenticated')) {
      return AuthenticationFailure(message: message, cause: error);
    }

    return DatabaseFailure(message: message, cause: error);
  }

  return UnknownFailure(message: fallback, cause: error);
}

String _readablePostgrestMessage(
  PostgrestException error, {
  required String fallback,
}) {
  final raw = error.message.trim();
  if (raw.isEmpty) return fallback;

  const prefixes = [
    'PostgrestException(message: ',
    'Exception: ',
  ];

  var message = raw;
  for (final prefix in prefixes) {
    if (message.startsWith(prefix)) {
      message = message.substring(prefix.length);
    }
  }

  message = message.replaceAll(RegExp(r"'\), code:.*$"), '').trim();
  message = message.replaceAll(RegExp(r'\), details:.*$'), '').trim();
  message = message.replaceAll(RegExp(r"^'|'$"), '').trim();

  if (message.isEmpty || message.toLowerCase().contains('postgrest')) {
    return fallback;
  }

  return message;
}
