import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppEnv {
  const AppEnv({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.environmentName,
  });

  factory AppEnv.fromDefines({
    String supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
    String supabasePublishableKey = const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
    String environmentName = const String.fromEnvironment(
      'MOMENT_ENV',
      defaultValue: 'development',
    ),
  }) {
    return AppEnv(
      supabaseUrl: supabaseUrl.trim(),
      supabasePublishableKey: supabasePublishableKey.trim(),
      environmentName: environmentName.trim().isEmpty
          ? 'development'
          : environmentName.trim(),
    );
  }

  factory AppEnv.fromJson(Map<String, dynamic> json) {
    return AppEnv(
      supabaseUrl: (json['SUPABASE_URL'] as String? ?? '').trim(),
      supabasePublishableKey:
          (json['SUPABASE_PUBLISHABLE_KEY'] as String? ??
                  json['SUPABASE_ANON_KEY'] as String? ??
                  '')
              .trim(),
      environmentName: (json['MOMENT_ENV'] as String? ?? 'development').trim(),
    );
  }

  final String supabaseUrl;
  final String supabasePublishableKey;
  final String environmentName;

  bool get isDevelopment => environmentName == 'development';
  bool get isProduction => environmentName == 'production';

  bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  void validate() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) {
      missing.add('SUPABASE_URL');
    }
    if (supabasePublishableKey.isEmpty) {
      missing.add('SUPABASE_PUBLISHABLE_KEY');
    }
    if (missing.isNotEmpty) {
      throw AppEnvException(
        'Missing environment values: ${missing.join(', ')}. '
        'Copy env.json.example to env.json, or run with '
        '--dart-define-from-file=env.json.',
      );
    }
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || !uri.isScheme('https') || uri.host.isEmpty) {
      throw const AppEnvException('SUPABASE_URL must be a valid https URL.');
    }
    if (supabasePublishableKey.startsWith('sb_secret_') ||
        supabasePublishableKey.contains('service_role')) {
      throw const AppEnvException(
        'Service-role credentials must never be used in the Moment client.',
      );
    }
  }
}

class AppEnvException implements Exception {
  const AppEnvException(this.message);

  final String message;

  @override
  String toString() => 'AppEnvException: $message';
}

/// Loads env from compile-time defines first, then bundled `env.json` in debug.
class EnvLoader {
  const EnvLoader._();

  static Future<AppEnv> load() async {
    final fromDefines = AppEnv.fromDefines();
    if (fromDefines.isConfigured) {
      return fromDefines;
    }

    if (kDebugMode || kProfileMode) {
      final fromAsset = await _loadFromAsset();
      if (fromAsset != null && fromAsset.isConfigured) {
        return fromAsset;
      }
    }

    return fromDefines;
  }

  static Future<AppEnv?> _loadFromAsset() async {
    try {
      final raw = await rootBundle.loadString('env.json');
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return AppEnv.fromJson(json);
    } on Object {
      return null;
    }
  }
}
