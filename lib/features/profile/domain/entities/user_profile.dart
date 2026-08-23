import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
  }

  @override
  List<Object?> get props => [id, username, displayName, avatarUrl, bio];
}

class ProfileUpdate extends Equatable {
  const ProfileUpdate({
    this.displayName,
    this.username,
    this.bio,
    this.avatarUrl,
  });

  final String? displayName;
  final String? username;
  final String? bio;
  final String? avatarUrl;

  Map<String, dynamic> toJson() {
    return {
      if (displayName != null) 'display_name': displayName,
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }

  @override
  List<Object?> get props => [displayName, username, bio, avatarUrl];
}
