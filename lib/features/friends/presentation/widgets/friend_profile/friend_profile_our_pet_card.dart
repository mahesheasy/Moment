import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/friends/presentation/theme/friend_profile_typography.dart';

class FriendProfileOurPetCard extends StatelessWidget {
  const FriendProfileOurPetCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Our Pet', style: FriendProfileTextStyles.sectionTitle),
            const SizedBox(height: 6),
            Text(
              'Care for a shared companion together — feed, play, and watch it grow.',
              style: FriendProfileTextStyles.sectionBody,
            ),
          ],
        ),
      ),
    );
  }
}
