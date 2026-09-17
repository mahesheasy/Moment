import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/core/widget/widget_background_reliability.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';

class AndroidWidgetBridge {
  const AndroidWidgetBridge();

  static const _channel = MethodChannel('app.moment/widget');

  Future<void> syncMoment({
    required Moment moment,
    required WidgetPreferences preferences,
    required String headerTitle,
    String headerEmoji = '',
    bool isUnread = true,
    int syncGeneration = 0,
  }) async {
    await syncReceivedMoments(
      moments: [moment],
      preferences: preferences,
      headerTitles: {moment.id: headerTitle},
      headerEmoji: headerEmoji,
      isUnreadByMomentId: {moment.id: isUnread},
      showLatest: true,
      syncGeneration: syncGeneration,
    );
  }

  Future<void> syncMoments({
    required List<Moment> moments,
    required WidgetPreferences preferences,
    required Map<String, String> headerTitles,
    String headerEmoji = '',
    bool showLatest = false,
    Map<String, bool>? isUnreadByMomentId,
    int syncGeneration = 0,
  }) async {
    if (!Platform.isAndroid || moments.isEmpty) return;

    final payload = <Map<String, dynamic>>[];
    for (final moment in moments) {
      payload.add({
        'momentId': moment.id,
        'senderId': moment.sender.id,
        'senderName': moment.sender.displayName,
        'caption': moment.caption ?? '',
        'relativeTime': relativeTimeAgo(moment.createdAt),
        'createdAtMillis': moment.createdAt.toUtc().millisecondsSinceEpoch,
        'isUnread': isUnreadByMomentId?[moment.id] ?? !moment.isSeen,
        if (moment.imageUrl != null) 'imageUrl': moment.imageUrl,
        if (moment.sender.avatarUrl != null) 'avatarUrl': moment.sender.avatarUrl,
      });
    }

    await _channel.invokeMethod<void>('updateWidget', {
      'moments': payload,
      'widgetMode': preferences.widgetMode.name,
      'headerEmoji': headerEmoji,
      'showLatest': showLatest,
      'syncGeneration': syncGeneration,
      'replaceQueue': true,
    });
  }

  Future<void> pushIncomingMoment({
    required Moment moment,
    required String headerTitle,
  }) async {
    if (!Platform.isAndroid) return;

    await _channel.invokeMethod<void>('pushIncomingMoment', {
      'momentId': moment.id,
      'senderId': moment.sender.id,
      'senderName': moment.sender.displayName,
      'caption': moment.caption ?? '',
      'relativeTime': relativeTimeAgo(moment.createdAt),
      'createdAtMillis': moment.createdAt.toUtc().millisecondsSinceEpoch,
      'isUnread': true,
      if (moment.imageUrl != null) 'imageUrl': moment.imageUrl,
      if (moment.sender.avatarUrl != null) 'avatarUrl': moment.sender.avatarUrl,
    });
  }

  /// Stores Supabase session on device so the widget can sync when the app is killed.
  Future<void> saveWidgetSyncSession({
    required String supabaseUrl,
    required String supabaseAnonKey,
    required String userId,
    required String accessToken,
    String? refreshToken,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('saveWidgetSyncSession', {
      'supabaseUrl': supabaseUrl,
      'supabaseAnonKey': supabaseAnonKey,
      'userId': userId,
      'accessToken': accessToken,
      'refreshToken': ?refreshToken,
    });
  }

  Future<void> clearWidgetSyncSession() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('clearWidgetSyncSession');
  }

  Future<void> syncReceivedMoments({
    required List<Moment> moments,
    required WidgetPreferences preferences,
    required Map<String, String> headerTitles,
    String headerEmoji = '',
    bool showLatest = false,
    Map<String, bool>? isUnreadByMomentId,
    int syncGeneration = 0,
  }) async {
    await syncMoments(
      moments: moments,
      preferences: preferences,
      headerTitles: headerTitles,
      headerEmoji: headerEmoji,
      showLatest: showLatest,
      isUnreadByMomentId: isUnreadByMomentId,
      syncGeneration: syncGeneration,
    );
  }

  Future<void> syncPreferences(
    WidgetPreferences preferences, {
    int streakCount = 0,
  }) async {
    if (!Platform.isAndroid) return;

    await _channel.invokeMethod<void>('syncPreferences', {
      'theme': preferences.theme.name,
      'accentColor': preferences.accentColor,
      'typography': preferences.typography.wireValue,
      'widgetMode': preferences.widgetMode.name,
      'displaySize': preferences.displaySize.wireValue,
      'showStreak': preferences.showStreak,
      'streakCount': streakCount,
      ..._privacyPayload(preferences),
    });
  }

  Future<WidgetPreferences?> readLocalPreferences() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getPreferences',
      );
      if (raw == null) return null;
      final hasCustomization = raw['hasCustomization'] as bool? ?? false;
      if (!hasCustomization) return null;

      return WidgetPreferences.fromJson({
        'theme': raw['theme'] as String? ?? 'minimal',
        'accent_color': raw['accentColor'] as String? ?? WidgetPreferences.defaultAccent,
        'typography': raw['typography'] as String? ?? 'default',
        'widget_mode': raw['widgetMode'] as String? ?? 'latest',
        'display_size': raw['displaySize'] as String? ?? 'large',
        'privacy_mode': raw['privacyMode'] as String? ?? 'full',
        'show_sender': raw['showSender'] as bool? ?? true,
        'show_timestamp': raw['showTimestamp'] as bool? ?? true,
        'show_captions': raw['showCaptions'] as bool? ?? false,
        'lock_screen_privacy': raw['lockScreenPrivacy'] as bool? ?? true,
        'paused': raw['paused'] as bool? ?? false,
        'privacy_person_id': _optionalId(raw['privacyPersonId']),
        'privacy_overrides': _parsePrivacyOverridesJson(raw['privacyOverridesJson']),
        'show_streak': raw['showStreak'] as bool? ?? true,
      });
    } on Object {
      return null;
    }
  }

  Future<WidgetPreferences?> readPrivacy() => readLocalPreferences();

  String? _optionalId(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }

  Map<String, Object> _privacyPayload(WidgetPreferences preferences) {
    return {
      'privacyMode': preferences.privacyMode.name,
      'showSender': preferences.showSender,
      'showTimestamp': preferences.showTimestamp,
      'showCaptions': preferences.showCaptions,
      'lockScreenPrivacy': preferences.lockScreenPrivacy,
      'paused': preferences.paused,
      'privacyPersonId': preferences.privacyPersonId ?? '',
      'privacyOverridesJson': jsonEncode({
        for (final entry in preferences.privacyOverrides.entries)
          entry.key: entry.value.name,
      }),
    };
  }

  Map<String, String> _parsePrivacyOverridesJson(Object? raw) {
    if (raw is! String || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return Map<String, String>.from(
        decoded.map((key, value) => MapEntry(key.toString(), value.toString())),
      );
    } on Object {
      return const {};
    }
  }

  Future<void> clear() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('clearWidget');
  }

  /// Clears unread on the native widget immediately (before full sync).
  Future<void> markMomentViewedOnDevice(String momentId) async {
    if (!Platform.isAndroid || momentId.isEmpty) return;
    await _channel.invokeMethod<void>('markMomentViewed', {
      'momentId': momentId,
    });
  }

  Future<bool> isPinSupported() async {
    if (!Platform.isAndroid) return false;
    final supported = await _channel.invokeMethod<bool>('isPinWidgetSupported');
    return supported ?? false;
  }

  Future<bool> requestPinToHomeScreen() async {
    if (!Platform.isAndroid) return false;
    final pinned = await _channel.invokeMethod<bool>('requestPinWidget');
    return pinned ?? false;
  }

  Future<WidgetBackgroundReliabilityStatus?> getBackgroundReliability() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getBackgroundReliability',
      );
      if (raw == null) return null;
      return WidgetBackgroundReliabilityStatus.fromMap(raw);
    } on Object {
      return null;
    }
  }

  Future<void> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('requestBatteryOptimizationExemption');
  }

  Future<void> openAutostartSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('openAutostartSettings');
  }
}
