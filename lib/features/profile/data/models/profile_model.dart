import 'package:moment/features/profile/domain/entities/user_profile.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
    );
  }

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
    );
  }
}
