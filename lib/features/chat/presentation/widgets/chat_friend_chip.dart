import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_hero_tags.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class ChatFriendChip extends StatelessWidget {
  const ChatFriendChip({
    required this.user,
    required this.onTap,
    super.key,
  });

  final UserProfile user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final firstName = user.displayName.split(' ').first;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Hero(
              tag: MomentHeroTags.chatAvatar(user.id),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ChatTheme.sentBubble(context).withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                  child: MomentAvatar(
                    name: user.displayName,
                    imageUrl: user.avatarUrl,
                    size: 52,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: mc.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatFriendsRow extends StatelessWidget {
  const ChatFriendsRow({
    required this.friends,
    required this.onTap,
    super.key,
  });

  final List<UserProfile> friends;
  final ValueChanged<UserProfile> onTap;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;

    if (friends.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            'New Chat',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: mc.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: friends.length.clamp(0, 16),
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final friend = friends[index];
              return ChatFriendChip(
                user: friend,
                onTap: () => onTap(friend),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
