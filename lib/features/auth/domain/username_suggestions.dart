import 'package:moment/features/auth/domain/validators/auth_validators.dart';

/// Generates clean, memorable username alternatives from display name / typed value.
abstract final class UsernameSuggestions {
  static List<String> generate({
    required String displayName,
    required String typedUsername,
    int limit = 3,
  }) {
    return candidates(
      displayName: displayName,
      typedUsername: typedUsername,
    ).take(limit).toList();
  }

  /// Ordered pool of username candidates to verify against the database.
  static List<String> candidates({
    required String displayName,
    required String typedUsername,
  }) {
    final base = _baseFrom(displayName, typedUsername);
    if (base.length < 3) return [];

    final raw = <String>[
      '${base}_g',
      '${base}_04',
      'g_$base',
      '${base}_m',
      '${base}_mom',
      'the_$base',
      '${base}_me',
      '${base}_01',
      '${base}_02',
      '${base}_real',
      'im_$base',
      '${base}_x',
    ];

    final normalizedTyped = AuthValidators.normalizeUsername(typedUsername);
    final results = <String>[];

    for (final candidate in raw) {
      final normalized = AuthValidators.normalizeUsername(candidate);
      if (normalized == normalizedTyped) continue;
      if (AuthValidators.validateUsername(normalized) != null) continue;
      if (results.contains(normalized)) continue;
      results.add(normalized);
    }

    return results;
  }

  static String _baseFrom(String displayName, String typedUsername) {
    final fromDisplay = _slug(displayName);
    if (fromDisplay.length >= 3) return fromDisplay;

    final fromTyped = _slug(typedUsername);
    if (fromTyped.length >= 3) return fromTyped;

    return fromDisplay.isNotEmpty ? fromDisplay : fromTyped;
  }

  static String _slug(String input) {
    final lowered = input.trim().toLowerCase();
    final cleaned = lowered.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final collapsed = cleaned.replaceAll(RegExp(r'_+'), '_');
    final trimmed = collapsed.replaceAll(RegExp(r'^_|_$'), '');
    if (trimmed.isEmpty) return '';
    return trimmed.length > 24 ? trimmed.substring(0, 24) : trimmed;
  }
}
