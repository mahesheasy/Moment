import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

Moment _moment({
  required String id,
  required String senderId,
  required bool isSeen,
}) {
  return Moment(
    id: id,
    sender: UserProfile(
      id: senderId,
      username: senderId,
      displayName: senderId,
    ),
    storagePath: '$id.jpg',
    createdAt: DateTime.utc(2026, 8, 16),
    isSeen: isSeen,
  );
}

void main() {
  test('home inbox keeps every unviewed moment from the same friend', () {
    final received = [
      _moment(id: '4', senderId: 'ada', isSeen: false),
      _moment(id: '3', senderId: 'ada', isSeen: false),
      _moment(id: '2', senderId: 'ada', isSeen: true),
      _moment(id: '1', senderId: 'ada', isSeen: false),
    ];

    final inbox = received.where((moment) => !moment.isSeen).toList();

    expect(inbox.map((moment) => moment.id), ['4', '3', '1']);
  });

  test('viewed moments leave the inbox and belong in memories', () {
    final received = [
      _moment(id: 'new', senderId: 'ada', isSeen: false),
      _moment(id: 'old', senderId: 'ada', isSeen: true),
    ];

    expect(
      received.where((moment) => !moment.isSeen).map((moment) => moment.id),
      ['new'],
    );
    expect(
      received.where((moment) => moment.isSeen).map((moment) => moment.id),
      ['old'],
    );
  });
}
