import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_hero_tags.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class ChatStoriesRow extends StatelessWidget {
  const ChatStoriesRow({
    required this.conversations,
    required this.friends,
    required this.onTapUser,
    super.key,
  });

  final List<ChatConversation> conversations;
  final List<UserProfile> friends;
  final ValueChanged<UserProfile> onTapUser;

  @override
  Widget build(BuildContext context) {
    final users = <UserProfile>[];
    final seen = <String>{};

    for (final conversation in conversations) {
      final user = conversation.otherUser;
      if (seen.add(user.id)) users.add(user);
    }
    for (final friend in friends) {
      if (seen.add(friend.id)) users.add(friend);
    }

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: 1 + users.length.clamp(0, 12),
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _MyNotesChip(
              onTap: () => context.push(AppRoutes.profile),
            );
          }
          final user = users[index - 1];
          final hasUnread = conversations
              .where((c) => c.otherUser.id == user.id)
              .any((c) => c.unreadCount > 0);
          return _StoryChip(
            user: user,
            hasUnread: hasUnread,
            onTap: () => onTapUser(user),
          );
        },
      ),
    );
  }
}

class _MyNotesChip extends StatelessWidget {
  const _MyNotesChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: ChatTheme.actionGradient,
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ChatTheme.threadBackground,
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: ChatTheme.accentPink,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'My Notes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryChip extends StatelessWidget {
  const _StoryChip({
    required this.user,
    required this.hasUnread,
    required this.onTap,
  });

  final UserProfile user;
  final bool hasUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstName = user.displayName.split(' ').first;
    final ringColor = hasUnread ? ChatTheme.accentPink : ChatTheme.onlineGreen;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Hero(
              tag: MomentHeroTags.chatAvatar(user.id),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2.5),
                    boxShadow: hasUnread
                        ? [
                            BoxShadow(
                              color: ChatTheme.accentPink.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      MomentAvatar(
                        name: user.displayName,
                        imageUrl: user.avatarUrl,
                        size: 54,
                      ),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: hasUnread
                                ? ChatTheme.accentPink
                                : ChatTheme.onlineGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ChatTheme.threadBackground,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
