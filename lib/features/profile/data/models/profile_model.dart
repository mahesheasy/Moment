import 'package:moment/features/profile/domain/entities/user_profile.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'];
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      createdAt: createdAtRaw is String
          ? DateTime.parse(createdAtRaw).toUtc()
          : null,
    );
  }

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime? createdAt;

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      createdAt: createdAt,
    );
  }
}
