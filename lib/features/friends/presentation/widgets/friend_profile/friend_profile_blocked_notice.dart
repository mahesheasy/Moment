import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/presentation/theme/friend_profile_typography.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class FriendProfileBlockedNotice extends StatelessWidget {
  const FriendProfileBlockedNotice({
    required this.profile,
    required this.relationship,
    super.key,
  });

  final UserProfile profile;
  final FriendRelationship relationship;

  @override
  Widget build(BuildContext context) {
    final firstName = profile.displayName.split(' ').first;

    final message = switch (relationship) {
      FriendRelationship.blocked =>
        'You have blocked $firstName. They can\'t message you or send friend requests.',
      FriendRelationship.blockedBy =>
        '$firstName has blocked you. You can\'t message or connect with them.',
      _ => '',
    };

    if (message.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: FriendProfileTextStyles.sectionBody.copyWith(
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}
