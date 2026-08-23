import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves circle avatar storage paths to signed URLs.
class CircleImageResolver {
  CircleImageResolver(this._client);

  final SupabaseClient _client;
  static const _bucket = 'circle-avatars';

  final Map<String, String> _cache = {};

  static bool isNetworkUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
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
}
