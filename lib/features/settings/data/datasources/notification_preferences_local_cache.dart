import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  const NotificationPreferences({
    this.pushEnabled = true,
    this.moments = true,
    this.friendRequests = true,
    this.mentions = true,
    this.memories = true,
    this.security = true,
    this.emailDigest = false,
  });

  final bool pushEnabled;
  final bool moments;
  final bool friendRequests;
  final bool mentions;
  final bool memories;
  final bool security;
  final bool emailDigest;

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? moments,
    bool? friendRequests,
    bool? mentions,
    bool? memories,
    bool? security,
    bool? emailDigest,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      moments: moments ?? this.moments,
      friendRequests: friendRequests ?? this.friendRequests,
      mentions: mentions ?? this.mentions,
      memories: memories ?? this.memories,
      security: security ?? this.security,
      emailDigest: emailDigest ?? this.emailDigest,
    );
  }

  Map<String, dynamic> toJson() => {
    'pushEnabled': pushEnabled,
    'moments': moments,
    'friendRequests': friendRequests,
    'mentions': mentions,
    'memories': memories,
    'security': security,
    'emailDigest': emailDigest,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      moments: json['moments'] as bool? ?? true,
      friendRequests: json['friendRequests'] as bool? ?? true,
      mentions: json['mentions'] as bool? ?? true,
      memories: json['memories'] as bool? ?? true,
      security: json['security'] as bool? ?? true,
      emailDigest: json['emailDigest'] as bool? ?? false,
    );
  }
}

class NotificationPreferencesLocalCache {
  static const _key = 'notification_preferences';

  Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const NotificationPreferences();
    try {
      return NotificationPreferences.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      return const NotificationPreferences();
    }
  }

  Future<void> save(NotificationPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(preferences.toJson()));
  }
}
