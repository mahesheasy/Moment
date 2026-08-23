import 'package:equatable/equatable.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

enum ReactionType {
  heart('heart', '❤️'),
  laugh('laugh', '😂'),
  fire('fire', '🔥'),
  love('love', '😍'),
  wow('wow', '😮');

  const ReactionType(this.value, this.emoji);

  final String value;
  final String emoji;

  static ReactionType? fromValue(String value) {
    for (final type in ReactionType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class MomentReactionSummary extends Equatable {
  const MomentReactionSummary({required this.counts, this.myReaction});

  final Map<ReactionType, int> counts;
  final ReactionType? myReaction;

  int get total => counts.values.fold(0, (sum, count) => sum + count);

  @override
  List<Object?> get props => [counts, myReaction];
}

class Ping extends Equatable {
  const Ping({
    required this.id,
    required this.senderId,
    required this.recipientId,
    this.momentId,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String recipientId;
  final String? momentId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, senderId, recipientId, momentId, createdAt];
}

class PingActivity extends Equatable {
  const PingActivity({
    required this.id,
    required this.counterpart,
    required this.sentByMe,
    required this.createdAt,
    this.emoji = '👋',
  });

  final String id;
  final UserProfile counterpart;
  final bool sentByMe;
  final DateTime createdAt;
  final String emoji;

  String get headline =>
      sentByMe ? 'You sent $emoji' : '${counterpart.displayName} sent $emoji';

  @override
  List<Object?> get props => [id, counterpart, sentByMe, createdAt, emoji];
}

class PingThread extends Equatable {
  const PingThread({required this.person, required this.pings});

  final UserProfile person;
  final List<PingActivity> pings;

  PingActivity get latest => pings.first;

  int get count => pings.length;

  List<String> get recentEmojis {
    final seen = <String>{};
    final emojis = <String>[];
    for (final ping in pings) {
      if (seen.add(ping.emoji)) emojis.add(ping.emoji);
      if (emojis.length == 3) break;
    }
    return emojis;
  }

  @override
  List<Object?> get props => [person, pings];
}

List<PingThread> groupPingsByPerson(List<PingActivity> recent) {
  final grouped = <String, List<PingActivity>>{};
  final order = <String>[];
  for (final ping in recent) {
    final id = ping.counterpart.id;
    if (grouped.putIfAbsent(id, () => []).isEmpty) {
      order.add(id);
    }
    grouped[id]!.add(ping);
  }
  return [
    for (final id in order)
      PingThread(person: grouped[id]!.first.counterpart, pings: grouped[id]!),
  ];
}
