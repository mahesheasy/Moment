import 'package:moment/core/utils/relative_time.dart';

/// Helpers for interpreting [UserProfile.lastSeenAt] as online/offline status.
abstract final class PresenceUtils {
  static const onlineThreshold = Duration(minutes: 3);

  static bool isOnline(DateTime? lastSeenAt, {DateTime? now}) {
    if (lastSeenAt == null) return false;
    final clock = (now ?? DateTime.now()).toUtc();
    return clock.difference(lastSeenAt.toUtc()) < onlineThreshold;
  }

  static String statusLabel({
    required bool isTyping,
    DateTime? lastSeenAt,
    DateTime? now,
  }) {
    if (isTyping) return 'typing...';
    if (isOnline(lastSeenAt, now: now)) return 'Online';
    if (lastSeenAt == null) return 'Offline';
    return 'Last seen ${relativeTimeAgo(lastSeenAt, now: now)}';
  }
}
