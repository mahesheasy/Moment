import 'package:shared_preferences/shared_preferences.dart';

/// Optimistic local read state for the home-screen widget.
/// Moments marked here are treated as read before Supabase confirms [seen_at].
class WidgetReadCache {
  const WidgetReadCache();

  static const _key = 'widget_read_moment_ids_v1';

  Future<void> markRead(String momentId) async {
    if (momentId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = _loadIds(prefs);
    if (ids.add(momentId)) {
      await prefs.setStringList(_key, ids.toList());
    }
  }

  Future<bool> isReadAsync(String momentId) async {
    if (momentId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return _loadIds(prefs).contains(momentId);
  }

  Future<bool> isEffectivelyRead({
    required String momentId,
    required bool serverIsSeen,
  }) async {
    if (serverIsSeen) return true;
    return isReadAsync(momentId);
  }

  Set<String> _loadIds(SharedPreferences prefs) {
    return prefs.getStringList(_key)?.toSet() ?? <String>{};
  }
}
