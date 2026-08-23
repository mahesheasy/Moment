import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:moment/core/utils/relative_time.dart';
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
  }) async {
    await syncReceivedMoments(
      moments: [moment],
      preferences: preferences,
      headerTitles: {moment.id: headerTitle},
      headerEmoji: headerEmoji,
    );
  }

  Future<void> syncMoments({
    required List<Moment> moments,
    required WidgetPreferences preferences,
    required Map<String, String> headerTitles,
    String headerEmoji = '',
  }) async {
    if (!Platform.isAndroid || moments.isEmpty) return;

    final payload = <Map<String, dynamic>>[];
    for (final moment in moments) {
      final imageBytes = await _downloadBytes(moment.imageUrl);
      final avatarBytes = await _downloadBytes(moment.sender.avatarUrl);
      payload.add({
        'momentId': moment.id,
        'senderId': moment.sender.id,
        'senderName': headerTitles[moment.id] ?? moment.sender.displayName,
        'caption': moment.caption ?? '',
        'relativeTime': relativeTimeAgo(moment.createdAt),
        'createdAtMillis': moment.createdAt.toUtc().millisecondsSinceEpoch,
        if (imageBytes != null) 'imageBytes': imageBytes,
        if (avatarBytes != null) 'avatarBytes': avatarBytes,
      });
    }

    await _channel.invokeMethod<void>('updateWidget', {
      'moments': payload,
      'widgetMode': preferences.widgetMode.name,
      'headerEmoji': headerEmoji,
    });
  }

  Future<void> syncReceivedMoments({
    required List<Moment> moments,
    required WidgetPreferences preferences,
    required Map<String, String> headerTitles,
    String headerEmoji = '',
  }) async {
    await syncMoments(
      moments: moments,
      preferences: preferences,
      headerTitles: headerTitles,
      headerEmoji: headerEmoji,
    );
  }

  Future<void> syncPreferences(WidgetPreferences preferences) async {
    if (!Platform.isAndroid) return;

    await _channel.invokeMethod<void>('syncPreferences', {
      'theme': preferences.theme.name,
      'accentColor': preferences.accentColor,
      'typography': preferences.typography.wireValue,
      'widgetMode': preferences.widgetMode.name,
      'displaySize': preferences.displaySize.wireValue,
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
    };
  }

  Future<void> clear() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('clearWidget');
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

  Future<Uint8List?> _downloadBytes(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        return consolidateHttpClientResponseBytes(response);
      }
      client.close(force: true);
    } on Object {
      return null;
    }
    return null;
  }
}
