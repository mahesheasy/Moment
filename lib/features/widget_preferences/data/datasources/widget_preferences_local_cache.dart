import 'dart:convert';

import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local cache so widget customization survives navigation and
/// non-premium saves (when Supabase rejects customization upserts).
class WidgetPreferencesLocalCache {
  const WidgetPreferencesLocalCache();

  static const _key = 'widget_preferences_local_v1';

  Future<void> save(WidgetPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(preferences.toJson()));
  }

  Future<WidgetPreferences?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return WidgetPreferences.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } on Object {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
