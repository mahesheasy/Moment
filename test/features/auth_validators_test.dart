import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/auth/domain/validators/auth_validators.dart';

void main() {
  test('validateUsername accepts valid usernames', () {
    expect(AuthValidators.validateUsername('mahesh'), isNull);
    expect(AuthValidators.validateUsername('user_01'), isNull);
  });

  test('validateUsername rejects invalid usernames', () {
    expect(AuthValidators.validateUsername('ab'), isNotNull);
    expect(AuthValidators.validateUsername('Bad-Name'), isNotNull);
  });

  test('validatePassword rejects empty password', () {
    expect(AuthValidators.validatePassword(''), isNotNull);
    expect(AuthValidators.validatePassword('short'), isNotNull);
    expect(AuthValidators.validatePassword('longenough'), isNull);
  });

  test('normalizeUsername lowercases input', () {
    expect(AuthValidators.normalizeUsername('Mahesh'), 'mahesh');
  });
}
