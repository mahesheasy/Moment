import 'package:shared_preferences/shared_preferences.dart';

class NotificationsReadLocalCache {
  static const _readKey = 'read_notification_ids';
  static const _dismissedKey = 'dismissed_notification_ids';

  Future<Set<String>> loadReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_readKey);
    if (raw == null) return {};
    return raw.toSet();
  }

  Future<Set<String>> loadDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_dismissedKey);
    if (raw == null) return {};
    return raw.toSet();
  }

  Future<void> markRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await loadReadIds()..add(id);
    await prefs.setStringList(_readKey, ids.toList());
  }

  Future<void> markDismissed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await loadDismissedIds()..add(id);
    await prefs.setStringList(_dismissedKey, ids.toList());
    await markRead(id);
  }

  Future<void> markAllRead(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await loadReadIds()..addAll(ids);
    await prefs.setStringList(_readKey, current.toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readKey);
    await prefs.remove(_dismissedKey);
  }
}
