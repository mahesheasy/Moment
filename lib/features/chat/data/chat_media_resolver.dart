import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves chat media storage paths to signed URLs.
class ChatMediaResolver {
  ChatMediaResolver(this._client);

  final SupabaseClient _client;
  static const _bucket = 'moments';
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

  void clearCache() => _cache.clear();
}
