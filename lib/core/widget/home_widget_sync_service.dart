import 'package:moment/core/config/app_features.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/core/widget/android_widget_bridge.dart';
import 'package:moment/core/widget/widget_display_resolver.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/moments/domain/repositories/moment_repository.dart';
import 'package:moment/features/widget_preferences/data/datasources/widget_preferences_local_cache.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';
import 'package:moment/features/widget_preferences/domain/repositories/widget_preferences_repository.dart';

/// Keeps the Android home-screen widget in sync without opening the Home tab.
class HomeWidgetSyncService {
  const HomeWidgetSyncService(
    this._moments,
    this._widgetBridge,
    this._widgetPreferences,
    this._circles,
    this._localCache,
  );

  final MomentRepository _moments;
  final AndroidWidgetBridge _widgetBridge;
  final WidgetPreferencesRepository _widgetPreferences;
  final CircleRepository _circles;
  final WidgetPreferencesLocalCache _localCache;

  static int _syncGeneration = 0;

  Future<void> sync({bool promoteLatest = false}) async {
    final generation = ++_syncGeneration;

    final prefsResult = await _widgetPreferences.getPreferences();
    final remote = switch (prefsResult) {
      Success(:final value) =>
        (value.isPremium || AppFeatures.momentPlusWidgetsUnlocked) &&
                value.savedPreferences != null
            ? value.savedPreferences!
            : value.preferences,
      Failed() => WidgetPreferences.defaults(),
    };
    final local =
        await _localCache.read() ?? await _widgetBridge.readLocalPreferences();
    if (generation != _syncGeneration) return;

    final preferences = local == null ? remote : remote.mergeLocal(local);

    final streakCount = switch (await _moments.getMomentStreak()) {
      Success(:final value) => value,
      Failed() => 0,
    };
    if (generation != _syncGeneration) return;

    await _widgetBridge.syncPreferences(
      preferences,
      streakCount: streakCount,
    );

    final momentsResult = await _moments.getWidgetMoments(preferences);
    if (generation != _syncGeneration) return;

    switch (momentsResult) {
      case Success(:final value) when value.isNotEmpty:
        final titles = <String, String>{};
        for (final moment in value) {
          final display = await resolveWidgetDisplay(
            preferences: preferences,
            moment: moment,
            circles: _circles,
          );
          titles[moment.id] = display.headerTitle;
        }
        if (generation != _syncGeneration) return;
        await _widgetBridge.syncReceivedMoments(
          moments: value,
          preferences: preferences,
          headerTitles: titles,
          headerEmoji: preferences.theme.emoji,
          showLatest: promoteLatest,
          syncGeneration: generation,
        );
      case Success():
        final fallback = await _moments.getWidgetMoment(preferences);
        if (generation != _syncGeneration) return;
        if (fallback case Success(:final value?)) {
          await pushMoment(
            moment: value,
            preferences: preferences,
            syncGeneration: generation,
          );
        }
      case Failed():
        break;
    }
  }

  Future<void> pushMoment({
    required Moment moment,
    required WidgetPreferences preferences,
    int syncGeneration = 0,
  }) async {
    final display = await resolveWidgetDisplay(
      preferences: preferences,
      moment: moment,
      circles: _circles,
    );
    await _widgetBridge.syncMoment(
      moment: moment,
      preferences: preferences,
      headerTitle: display.headerTitle,
      headerEmoji: display.headerEmoji,
      syncGeneration: syncGeneration,
    );
  }
}
