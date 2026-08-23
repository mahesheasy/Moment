import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';

void main() {
  test('CircleType fromValue parses known types', () {
    expect(CircleType.fromValue('us'), CircleType.us);
    expect(CircleType.fromValue('squad'), CircleType.squad);
    expect(CircleType.fromValue('family'), CircleType.family);
    expect(CircleType.fromValue('college'), CircleType.college);
    expect(CircleType.fromValue('custom'), CircleType.custom);
    expect(CircleType.fromValue('unknown'), CircleType.custom);
  });

  test('CircleType labels and default emojis match spec', () {
    expect(CircleType.us.label, 'Us');
    expect(CircleType.squad.defaultEmoji, '👥');
    expect(CircleType.family.defaultEmoji, '👨‍👩‍👧');
    expect(CircleType.college.defaultEmoji, '🎓');
  });

  test('Circle displayEmoji prefers custom emoji', () {
    final circle = Circle(
      id: '1',
      name: 'Weekend',
      type: CircleType.squad,
      ownerId: 'owner',
      emoji: '🎉',
      memberCount: 3,
      createdAt: DateTime.utc(2026, 8, 15),
    );

    expect(circle.displayEmoji, '🎉');
  });

  test('CircleLimits caps a circle at 20 members', () {
    expect(CircleLimits.maxMembers, 20);
  });
}
