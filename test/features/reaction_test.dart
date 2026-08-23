import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

void main() {
  test('ReactionType fromValue parses known reactions', () {
    expect(ReactionType.fromValue('heart'), ReactionType.heart);
    expect(ReactionType.fromValue('wow'), ReactionType.wow);
    expect(ReactionType.fromValue('unknown'), isNull);
  });

  test('ReactionType emojis match spec', () {
    expect(ReactionType.heart.emoji, '❤️');
    expect(ReactionType.laugh.emoji, '😂');
    expect(ReactionType.fire.emoji, '🔥');
    expect(ReactionType.love.emoji, '😍');
    expect(ReactionType.wow.emoji, '😮');
  });

  test('PingActivity headline uses the stored emoji', () {
    final activity = PingActivity(
      id: 'p1',
      counterpart: const UserProfile(
        id: 'u1',
        username: 'ada',
        displayName: 'Ada',
      ),
      sentByMe: true,
      createdAt: DateTime.utc(2026, 8, 16),
      emoji: '☕',
    );
    expect(activity.headline, 'You sent ☕');
  });

  test('groupPingsByPerson keeps one thread per friend', () {
    const yakesh = UserProfile(
      id: 'y',
      username: 'yakesh',
      displayName: 'Yakesh',
    );
    final recent = [
      PingActivity(
        id: '1',
        counterpart: yakesh,
        sentByMe: true,
        createdAt: DateTime.utc(2026, 8, 16, 12),
        emoji: '👋',
      ),
      PingActivity(
        id: '2',
        counterpart: yakesh,
        sentByMe: false,
        createdAt: DateTime.utc(2026, 8, 16, 11),
        emoji: '❤️',
      ),
      PingActivity(
        id: '3',
        counterpart: const UserProfile(
          id: 'a',
          username: 'ada',
          displayName: 'Ada',
        ),
        sentByMe: true,
        createdAt: DateTime.utc(2026, 8, 16, 10),
        emoji: '☕',
      ),
    ];

    final threads = groupPingsByPerson(recent);
    expect(threads, hasLength(2));
    expect(threads.first.person.displayName, 'Yakesh');
    expect(threads.first.count, 2);
    expect(threads.first.recentEmojis, ['👋', '❤️']);
    expect(threads.last.person.displayName, 'Ada');
  });
}
