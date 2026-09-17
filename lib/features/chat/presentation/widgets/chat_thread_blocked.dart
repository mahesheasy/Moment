import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class ChatThreadBlockedNotice extends StatelessWidget {
  const ChatThreadBlockedNotice({
    required this.user,
    required this.relationship,
    this.centered = false,
    super.key,
  });

  final UserProfile user;
  final FriendRelationship relationship;
  final bool centered;

  String get _message {
    final firstName = user.displayName.split(' ').first;
    return switch (relationship) {
      FriendRelationship.blocked =>
        'You have blocked $firstName. Unblock them to send messages again.',
      FriendRelationship.blockedBy =>
        '$firstName has blocked you. You can\'t send messages in this chat.',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_message.isEmpty) return const SizedBox.shrink();

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.block_rounded,
          size: centered ? 40 : 20,
          color: Colors.white.withValues(alpha: 0.35),
        ),
        SizedBox(height: centered ? AppSpacing.lg : AppSpacing.sm),
        Text(
          _message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: centered ? 15 : 13,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: MomentSpaceTheme.textSecondary(context),
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );

    if (centered) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: content,
    );
  }
}

class ChatThreadBlockedBar extends StatelessWidget {
  const ChatThreadBlockedBar({
    required this.user,
    required this.relationship,
    required this.isActing,
    this.onUnblock,
    super.key,
  });

  final UserProfile user;
  final FriendRelationship relationship;
  final bool isActing;
  final VoidCallback? onUnblock;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: MomentSpaceTheme.composerBarBackground(context),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChatThreadBlockedNotice(
            user: user,
            relationship: relationship,
          ),
          if (relationship == FriendRelationship.blocked &&
              onUnblock != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: isActing ? null : onUnblock,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: isActing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Unblock',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
