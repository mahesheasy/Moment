import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/profile/data/models/profile_model.dart';

class FriendRequestModel {
  const FriendRequestModel({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id'] as String,
      sender: ProfileModel.fromJson(
        Map<String, dynamic>.from(json['sender'] as Map),
      ),
      receiver: ProfileModel.fromJson(
        Map<String, dynamic>.from(json['receiver'] as Map),
      ),
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final ProfileModel sender;
  final ProfileModel receiver;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequest toEntity() {
    return FriendRequest(
      id: id,
      sender: sender.toEntity(),
      receiver: receiver.toEntity(),
      status: status,
      createdAt: createdAt,
    );
  }

  static FriendRequestStatus _parseStatus(String value) {
    return FriendRequestStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => FriendRequestStatus.pending,
    );
  }
}

class FriendSummaryModel {
  const FriendSummaryModel({required this.profile, required this.since});

  factory FriendSummaryModel.fromJson(Map<String, dynamic> json) {
    return FriendSummaryModel(
      profile: ProfileModel.fromJson(
        Map<String, dynamic>.from(json['friend'] as Map),
      ),
      since: DateTime.parse(json['created_at'] as String),
    );
  }

  final ProfileModel profile;
  final DateTime since;

  FriendSummary toEntity() {
    return FriendSummary(profile: profile.toEntity(), since: since);
  }
}

class BlockedUserModel {
  const BlockedUserModel({required this.profile, required this.blockedAt});

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      profile: ProfileModel.fromJson(
        Map<String, dynamic>.from(json['blocked'] as Map),
      ),
      blockedAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final ProfileModel profile;
  final DateTime blockedAt;

  BlockedUser toEntity() {
    return BlockedUser(profile: profile.toEntity(), blockedAt: blockedAt);
  }
}
