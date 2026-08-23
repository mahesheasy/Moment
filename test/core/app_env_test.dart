import 'package:flutter_test/flutter_test.dart';
import 'package:moment/core/config/app_env.dart';

void main() {
  group('AppEnv', () {
    test('validate accepts a publishable client configuration', () {
      const env = AppEnv(
        supabaseUrl: 'https://rqnzwvzziqflgipxiciz.supabase.co',
        supabasePublishableKey: 'sb_publishable_test_key',
        environmentName: 'development',
      );

      expect(env.validate, returnsNormally);
      expect(env.isDevelopment, isTrue);
    });

    test('validate rejects missing values', () {
      const env = AppEnv(
        supabaseUrl: '',
        supabasePublishableKey: '',
        environmentName: 'development',
      );

      expect(env.validate, throwsA(isA<AppEnvException>()));
    });

    test('validate rejects a non-https URL', () {
      const env = AppEnv(
        supabaseUrl: 'http://localhost:54321',
        supabasePublishableKey: 'sb_publishable_test_key',
        environmentName: 'development',
      );

      expect(env.validate, throwsA(isA<AppEnvException>()));
    });

    test('validate rejects service-role credentials', () {
      const env = AppEnv(
        supabaseUrl: 'https://rqnzwvzziqflgipxiciz.supabase.co',
        supabasePublishableKey: 'service_role_secret',
        environmentName: 'development',
      );

      expect(env.validate, throwsA(isA<AppEnvException>()));
    });

    test('fromJson parses env file shape', () {
      final env = AppEnv.fromJson({
        'SUPABASE_URL': 'https://example.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
        'MOMENT_ENV': 'development',
      });

      expect(env.supabaseUrl, 'https://example.supabase.co');
      expect(env.supabasePublishableKey, 'sb_publishable_test');
      expect(env.isConfigured, isTrue);
    });
  });
}
