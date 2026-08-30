import 'dart:async';

import 'package:moment/core/config/app_features.dart';
import 'package:moment/core/realtime/moment_realtime_subscriber.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/core/widget/android_widget_bridge.dart';
import 'package:moment/core/widget/widget_display_resolver.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/moments/domain/repositories/moment_repository.dart';
import 'package:moment/features/widget_preferences/data/datasources/widget_preferences_local_cache.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';
import 'package:moment/features/widget_preferences/domain/repositories/widget_preferences_repository.dart';

/// Pushes each realtime moment straight to the native home widget — no batch sync delay.
class WidgetMomentStreamService {
  WidgetMomentStreamService(
    this._realtime,
    this._moments,
    this._widgetBridge,
    this._widgetPreferences,
    this._circles,
    this._localCache,
  );

  final MomentRealtimeSubscriber _realtime;
  final MomentRepository _moments;
  final AndroidWidgetBridge _widgetBridge;
  final WidgetPreferencesRepository _widgetPreferences;
  final CircleRepository _circles;
  final WidgetPreferencesLocalCache _localCache;

  final Set<String> _inflight = <String>{};
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _realtime.listen(_onMomentInserted);
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _realtime.dispose();
  }

  Future<void> _onMomentInserted(String momentId) async {
    if (_inflight.contains(momentId)) return;
    _inflight.add(momentId);
    try {
      final preferences = await _loadPreferences();
      final momentResult = await _moments.getMoment(momentId);
      if (momentResult case Success(:final value)) {
        if (!_isEligible(value, preferences)) return;
        final display = await resolveWidgetDisplay(
          preferences: preferences,
          moment: value,
          circles: _circles,
        );
        await _widgetBridge.pushIncomingMoment(
          moment: value,
          headerTitle: display.headerTitle,
        );
      }
    } finally {
      _inflight.remove(momentId);
    }
  }

  bool _isEligible(Moment moment, WidgetPreferences preferences) {
    return switch (preferences.widgetMode) {
      WidgetMode.latest => true,
      WidgetMode.person =>
        preferences.selectedPersonId == moment.sender.id,
      WidgetMode.circle => true,
    };
  }

  Future<WidgetPreferences> _loadPreferences() async {
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
    return local == null ? remote : remote.mergeLocal(local);
  }
}
