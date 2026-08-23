import 'dart:developer' as developer;

class AppLogger {
  const AppLogger();

  static const _sensitiveKeyFragments = [
    'key',
    'token',
    'secret',
    'password',
    'authorization',
    'cookie',
    'session',
  ];

  void debug(String message, {Map<String, Object?>? context}) {
    _log('DEBUG', message, context: context);
  }

  void info(String message, {Map<String, Object?>? context}) {
    _log('INFO', message, context: context);
  }

  void warn(String message, {Map<String, Object?>? context}) {
    _log('WARN', message, context: context);
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    _log(
      'ERROR',
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Map<String, Object?> sanitize(Map<String, Object?> context) {
    return context.map((key, value) {
      final lower = key.toLowerCase();
      final sensitive = _sensitiveKeyFragments.any(lower.contains);
      return MapEntry(key, sensitive ? '[redacted]' : value);
    });
  }

  void _log(
    String level,
    String message, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final suffix = context == null || context.isEmpty
        ? ''
        : ' ${sanitize(context)}';
    developer.log(
      '$message$suffix',
      name: 'moment.$level',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
