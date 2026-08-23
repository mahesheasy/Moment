import 'package:equatable/equatable.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

enum CircleType {
  us('us', 'Us', '💑'),
  squad('squad', 'Squad', '👥'),
  family('family', 'Family', '👨‍👩‍👧'),
  college('college', 'College', '🎓'),
  custom('custom', 'Custom', '✨');

  const CircleType(this.value, this.label, this.defaultEmoji);

  final String value;
  final String label;
  final String defaultEmoji;

  static CircleType fromValue(String value) {
    return CircleType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CircleType.custom,
    );
  }
}

class CircleLimits {
  const CircleLimits._();

  static const int maxMembers = 20;
}

/// Latest activity shown on the circles list.
class CircleActivitySummary extends Equatable {
  const CircleActivitySummary({
    this.momentCount = 0,
    this.latestSenderName,
    this.latestActivityAt,
    this.latestImageUrl,
  });

  final int momentCount;
  final String? latestSenderName;
  final DateTime? latestActivityAt;
  final String? latestImageUrl;

  @override
  List<Object?> get props => [
    momentCount,
    latestSenderName,
    latestActivityAt,
    latestImageUrl,
  ];
}

class Circle extends Equatable {
  const Circle({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    this.emoji,
    this.avatarUrl,
    required this.memberCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final CircleType type;
  final String ownerId;
  final String? emoji;
  final String? avatarUrl;
  final int memberCount;
  final DateTime createdAt;

  String get displayEmoji => emoji ?? type.defaultEmoji;

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    ownerId,
    emoji,
    avatarUrl,
    memberCount,
    createdAt,
  ];
}

class CircleMember extends Equatable {
  const CircleMember({
    required this.profile,
    required this.role,
    required this.joinedAt,
  });

  final UserProfile profile;
  final String role;
  final DateTime joinedAt;

  bool get isOwner => role == 'owner';

  @override
  List<Object?> get props => [profile, role, joinedAt];
}

class CreateCircleInput extends Equatable {
  const CreateCircleInput({
    required this.name,
    required this.type,
    this.emoji,
    this.memberIds = const [],
  });

  final String name;
  final CircleType type;
  final String? emoji;
  final List<String> memberIds;

  @override
  List<Object?> get props => [name, type, emoji, memberIds];
}
