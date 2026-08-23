import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:moment/core/theme/accent_presets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark }

class AppearancePreferences {
  const AppearancePreferences({
    this.theme = AppThemePreference.dark,
    this.accentHex = kDefaultAccentHex,
  });

  final AppThemePreference theme;
  final String accentHex;

  AppearancePreferences copyWith({
    AppThemePreference? theme,
    String? accentHex,
  }) {
    return AppearancePreferences(
      theme: theme ?? this.theme,
      accentHex: accentHex ?? this.accentHex,
    );
  }

  ThemeMode get themeMode => switch (theme) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  Map<String, dynamic> toJson() => {
    'theme': theme.name,
    'accentHex': accentHex,
  };

  factory AppearancePreferences.fromJson(Map<String, dynamic> json) {
    final themeName = json['theme'] as String? ?? 'dark';
    return AppearancePreferences(
      theme: AppThemePreference.values.firstWhere(
        (value) => value.name == themeName,
        orElse: () => AppThemePreference.dark,
      ),
      accentHex: json['accentHex'] as String? ?? kDefaultAccentHex,
    );
  }
}

class AppearancePreferencesLocalCache {
  static const _key = 'appearance_preferences_v1';

  Future<AppearancePreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const AppearancePreferences();
    try {
      return AppearancePreferences.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      return const AppearancePreferences();
    }
  }

  Future<void> save(AppearancePreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(preferences.toJson()));
  }
}
