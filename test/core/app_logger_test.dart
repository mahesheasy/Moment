import 'package:flutter_test/flutter_test.dart';
import 'package:moment/core/logging/app_logger.dart';

void main() {
  test('redacts sensitive context keys', () {
    const logger = AppLogger();
    final sanitized = logger.sanitize({
      'userId': 'abc',
      'accessToken': 'super-secret',
      'publishableKey': 'sb_publishable_x',
    });

    expect(sanitized['userId'], 'abc');
    expect(sanitized['accessToken'], '[redacted]');
    expect(sanitized['publishableKey'], '[redacted]');
  });
}
