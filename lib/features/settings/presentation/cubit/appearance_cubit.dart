import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/theme/accent_presets.dart';
import 'package:moment/features/settings/data/datasources/appearance_preferences_local_cache.dart';

class AppearanceState {
  const AppearanceState({
    this.preferences = const AppearancePreferences(),
    this.isLoaded = false,
  });

  final AppearancePreferences preferences;
  final bool isLoaded;

  ThemeMode get themeMode => preferences.themeMode;

  Color get accentColor => accentFromHex(preferences.accentHex);

  AppearanceState copyWith({
    AppearancePreferences? preferences,
    bool? isLoaded,
  }) {
    return AppearanceState(
      preferences: preferences ?? this.preferences,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class AppearanceCubit extends Cubit<AppearanceState> {
  AppearanceCubit(this._cache) : super(const AppearanceState());

  final AppearancePreferencesLocalCache _cache;

  Future<void> load() async {
    final preferences = await _cache.load();
    emit(AppearanceState(preferences: preferences, isLoaded: true));
  }

  Future<void> setTheme(AppThemePreference theme) async {
    final next = state.preferences.copyWith(theme: theme);
    emit(state.copyWith(preferences: next));
    await _cache.save(next);
  }

  Future<void> setAccentHex(String accentHex) async {
    final next = state.preferences.copyWith(accentHex: accentHex);
    emit(state.copyWith(preferences: next));
    await _cache.save(next);
  }
}
