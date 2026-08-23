import 'package:equatable/equatable.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

enum FriendRequestStatus { pending, accepted, rejected, cancelled }

enum FriendRelationship {
  none,
  friends,
  requestSent,
  requestReceived,
  blocked,
  blockedBy,
}

class FriendRequest extends Equatable {
  const FriendRequest({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final UserProfile sender;
  final UserProfile receiver;
  final FriendRequestStatus status;
  final DateTime createdAt;

  bool get isPending => status == FriendRequestStatus.pending;

  @override
  List<Object?> get props => [id, sender, receiver, status, createdAt];
}

class FriendSummary extends Equatable {
  const FriendSummary({required this.profile, required this.since});

  final UserProfile profile;
  final DateTime since;

  @override
  List<Object?> get props => [profile, since];
}

class BlockedUser extends Equatable {
  const BlockedUser({required this.profile, required this.blockedAt});

  final UserProfile profile;
  final DateTime blockedAt;

  @override
  List<Object?> get props => [profile, blockedAt];
}

class UserSearchResult extends Equatable {
  const UserSearchResult({
    required this.profile,
    required this.relationship,
    this.pendingRequestId,
    this.mutualFriendCount = 0,
  });

  final UserProfile profile;
  final FriendRelationship relationship;
  final String? pendingRequestId;
  final int mutualFriendCount;

  @override
  List<Object?> get props => [
    profile,
    relationship,
    pendingRequestId,
    mutualFriendCount,
  ];
}

class SuggestedFriend extends Equatable {
  const SuggestedFriend({
    required this.profile,
    required this.mutualFriendCount,
    required this.relationship,
    this.pendingRequestId,
  });

  final UserProfile profile;
  final int mutualFriendCount;
  final FriendRelationship relationship;
  final String? pendingRequestId;

  @override
  List<Object?> get props => [
    profile,
    mutualFriendCount,
    relationship,
    pendingRequestId,
  ];
}
