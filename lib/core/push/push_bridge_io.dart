import 'dart:io';

import 'package:flutter/services.dart';
import 'package:moment/features/settings/data/datasources/notification_preferences_local_cache.dart';

/// Thin wrapper over the native FCM registration channel.
///
/// Message delivery is handled entirely in Kotlin so the widget can update
/// while the app is killed; Dart only needs the token.
class PushBridge {
  const PushBridge();

  static const _channel = MethodChannel('app.moment/push');

  Future<String?> getToken() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('getToken');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('hasNotificationPermission') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'requestNotificationPermission',
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> deleteToken() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('deleteToken');
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<void> syncNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(
        'syncNotificationPreferences',
        {
          'push_enabled': preferences.pushEnabled,
          'moments': preferences.moments,
          'friend_requests': preferences.friendRequests,
          'mentions': preferences.mentions,
          'memories': preferences.memories,
          'security': preferences.security,
          'email_digest': preferences.emailDigest,
        },
      );
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
