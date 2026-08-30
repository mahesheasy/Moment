import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/friends/presentation/theme/friend_profile_typography.dart';

class FriendProfilePrivateSpaceCard extends StatelessWidget {
  const FriendProfilePrivateSpaceCard({
    required this.onTap,
    super.key,
  });

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
            Text('Private Space', style: FriendProfileTextStyles.sectionTitle),
            const SizedBox(height: 6),
            Text(
              "You're connected. Share your real moments.",
              style: FriendProfileTextStyles.sectionBody,
            ),
          ],
        ),
      ),
    );
  }
}
