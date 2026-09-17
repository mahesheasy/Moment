import 'package:flutter_test/flutter_test.dart';
import 'package:moment/core/widget/widget_moment_selector.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

Moment _moment(String id, DateTime createdAt, {bool isSeen = false}) {
  return Moment(
    id: id,
    sender: UserProfile(id: 's-$id', username: 'friend', displayName: 'Friend'),
    storagePath: 'path/$id',
    createdAt: createdAt,
    isSeen: isSeen,
  );
}

void main() {
  test('selectWidgetMoment prefers newest unread', () {
    final unseen = [
      _moment('a', DateTime(2026, 1, 1, 10)),
      _moment('b', DateTime(2026, 1, 1, 11)),
    ];

    final selection = selectWidgetMoment(unseen: unseen);

    expect(selection.moment?.id, 'b');
    expect(selection.isUnread, isTrue);
  });

  test('selectWidgetMoment returns empty when all moments are read', () {
    final selection = selectWidgetMoment(unseen: const []);

    expect(selection.moment, isNull);
    expect(selection.isUnread, isFalse);
  });
}
