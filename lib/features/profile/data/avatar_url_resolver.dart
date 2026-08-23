import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves avatar storage paths to signed URLs for display.
class AvatarUrlResolver {
  AvatarUrlResolver(this._client);

  final SupabaseClient _client;
  static const _bucket = 'avatars';

  final Map<String, String> _cache = {};

  static bool isNetworkUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  /// Returns true when [value] is a Supabase storage path, not a loadable URL.
  static bool isStoragePath(String? value) {
    if (value == null || value.isEmpty) return false;
    return !isNetworkUrl(value);
  }

  Future<String?> resolve(String? value) async {
    if (value == null || value.trim().isEmpty) return null;
    if (isNetworkUrl(value)) return value;

    final cached = _cache[value];
    if (cached != null) return cached;

    try {
      final signed = await _client.storage
          .from(_bucket)
          .createSignedUrl(value, 3600);
      _cache[value] = signed;
      return signed;
    } on Object {
      return null;
    }
  }

  void invalidate(String? storagePath) {
    if (storagePath != null) _cache.remove(storagePath);
  }

  void clearCache() => _cache.clear();
}
