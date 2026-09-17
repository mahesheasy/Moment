import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class ChatThreadRestrictedNotice extends StatelessWidget {
  const ChatThreadRestrictedNotice({
    required this.user,
    required this.relationship,
    this.reportAcknowledged = false,
    this.onPrimaryAction,
    this.primaryActionLabel,
    super.key,
  });

  final UserProfile user;
  final FriendRelationship relationship;
  final bool reportAcknowledged;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;

  String get _title {
    if (reportAcknowledged) return 'Report submitted';
    return switch (relationship) {
      FriendRelationship.requestSent => 'Request pending',
      FriendRelationship.requestReceived => 'Respond to request',
      _ => 'Messaging unavailable',
    };
  }

  String get _message {
    final firstName = user.displayName.split(' ').first;
    if (reportAcknowledged) {
      return 'Thanks for letting us know. This chat with $firstName is closed for now.';
    }
    return switch (relationship) {
      FriendRelationship.requestSent =>
        'Your friend request to $firstName is still pending.',
      FriendRelationship.requestReceived =>
        '$firstName sent you a friend request. Accept it to start messaging.',
      _ => 'You and $firstName need to be friends before you can send messages.',
    };
  }

  IconData get _icon {
    if (reportAcknowledged) return Icons.flag_rounded;
    return switch (relationship) {
      FriendRelationship.requestSent => Icons.hourglass_top_rounded,
      FriendRelationship.requestReceived => Icons.person_add_rounded,
      _ => Icons.chat_bubble_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = MomentSpaceTheme.composerAccent(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.mc.surface.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(
                _icon,
                size: 32,
                color: reportAcknowledged
                    ? const Color(0xFFFF9F0A)
                    : accent.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: MomentSpaceTheme.textPrimary(context),
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: MomentSpaceTheme.textSecondary(context),
                decoration: TextDecoration.none,
              ),
            ),
            if (onPrimaryAction != null && primaryActionLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: onPrimaryAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    primaryActionLabel!,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ChatThreadRestrictedBar extends StatelessWidget {
  const ChatThreadRestrictedBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: MomentSpaceTheme.composerBarBackground(context),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Text(
        'Messaging is disabled in this chat',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: MomentSpaceTheme.textSecondary(context),
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
