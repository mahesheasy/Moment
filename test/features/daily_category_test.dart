import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/memories/domain/entities/daily_category.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

UserProfile _person(String id, String name) {
  return UserProfile(id: id, username: id, displayName: name);
}

Moment _moment(String id, UserProfile sender) {
  return Moment(
    id: id,
    sender: sender,
    storagePath: '$id.jpg',
    createdAt: DateTime.utc(2026, 8, 16),
    isSeen: true,
  );
}

void main() {
  final ada = _person('ada', 'Ada');
  final mom = _person('mom', 'Mom');
  final family = Circle(
    id: 'fam',
    name: 'Family',
    type: CircleType.family,
    ownerId: 'me',
    memberCount: 2,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  test('one friend becomes one person category', () {
    final categories = buildDailyCategories(
      moments: [_moment('1', ada), _moment('2', ada)],
      circles: const [],
      membersByCircle: const {},
    );

    expect(categories, hasLength(1));
    expect(categories.first.kind, DailyCategoryKind.person);
    expect(categories.first.title, 'Ada');
    expect(categories.first.moments, hasLength(2));
  });

  test(
    'family members become a family category, other friends stay people',
    () {
      final categories = buildDailyCategories(
        moments: [_moment('f1', mom), _moment('a1', ada)],
        circles: [family],
        membersByCircle: {
          'fam': [mom],
        },
      );

      expect(categories.map((category) => category.title), ['Family', 'Ada']);
      expect(categories.first.kind, DailyCategoryKind.circle);
      expect(categories.last.kind, DailyCategoryKind.person);
    },
  );
}
