import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/presentation/theme/friend_profile_theme.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class FriendProfileActions extends StatelessWidget {
  const FriendProfileActions({
    required this.userId,
    required this.profile,
    required this.relationship,
    required this.pendingRequestId,
    required this.isActing,
    required this.onMessage,
    required this.onPrivateSpace,
    required this.onRemoveFriend,
    required this.onAddFriend,
    required this.onAccept,
    required this.onDecline,
    required this.onCancelRequest,
    required this.onBlock,
    required this.onReport,
    this.onUnblock,
    super.key,
  });

  final String userId;
  final UserProfile profile;
  final FriendRelationship relationship;
  final String? pendingRequestId;
  final bool isActing;
  final VoidCallback onMessage;
  final VoidCallback onPrivateSpace;
  final Future<void> Function() onRemoveFriend;
  final VoidCallback? onAddFriend;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancelRequest;
  final VoidCallback onBlock;
  final VoidCallback onReport;
  final Future<void> Function()? onUnblock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._primaryActions(context),
        if (_showDestructiveActions) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DestructiveTextAction(
                icon: Icons.block_rounded,
                label: 'Block',
                onTap: isActing ? null : onBlock,
              ),
              const SizedBox(width: AppSpacing.xxl),
              _DestructiveTextAction(
                icon: Icons.flag_outlined,
                label: 'Report',
                onTap: isActing ? null : onReport,
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool get _showDestructiveActions =>
      relationship != FriendRelationship.blocked &&
      relationship != FriendRelationship.blockedBy;

  List<Widget> _primaryActions(BuildContext context) {
    switch (relationship) {
      case FriendRelationship.friends:
        return [
          _MessageButton(onTap: isActing ? null : onMessage),
          const SizedBox(height: AppSpacing.md),
          _SecondaryPillButton(
            label: 'Remove friend',
            icon: Icons.person_remove_outlined,
            isLoading: isActing,
            onTap: isActing ? null : onRemoveFriend,
          ),
        ];
      case FriendRelationship.requestSent:
        return [
          _SecondaryPillButton(
            label: 'Cancel request',
            icon: Icons.hourglass_empty_rounded,
            isLoading: isActing,
            onTap: isActing || pendingRequestId == null ? null : () async => onCancelRequest?.call(),
          ),
        ];
      case FriendRelationship.requestReceived:
        return [
          _MessageButton(
            label: 'Accept',
            icon: Icons.check_rounded,
            onTap: isActing || pendingRequestId == null ? null : () async => onAccept?.call(),
          ),
          const SizedBox(height: AppSpacing.md),
          _SecondaryPillButton(
            label: 'Decline',
            icon: Icons.close_rounded,
            isLoading: isActing,
            onTap: isActing || pendingRequestId == null ? null : () async => onDecline?.call(),
          ),
        ];
      case FriendRelationship.none:
        return [
          _MessageButton(
            label: 'Add friend',
            icon: Icons.person_add_alt_1_rounded,
            onTap: isActing ? null : onAddFriend,
          ),
        ];
      case FriendRelationship.blocked:
        return [
          _SecondaryPillButton(
            label: 'Unblock',
            icon: Icons.lock_open_rounded,
            isLoading: isActing,
            onTap: isActing ? null : onUnblock,
          ),
        ];
      case FriendRelationship.blockedBy:
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'No actions available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textTertiaryDark,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ];
    }
  }
}

class _MessageButton extends StatelessWidget {
  const _MessageButton({
    required this.onTap,
    this.label = 'Message',
    this.icon = Icons.chat_bubble_rounded,
  });

  final VoidCallback? onTap;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FriendProfileTheme.buttonHeight,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FriendProfileTheme.buttonRadius),
          gradient: FriendProfileTheme.messageButtonGradient,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5B7A).withValues(alpha: 0.32),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(FriendProfileTheme.buttonRadius),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryPillButton extends StatelessWidget {
  const _SecondaryPillButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final Future<void> Function()? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FriendProfileTheme.secondaryButtonHeight,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading || onTap == null
            ? null
            : () async => onTap!(),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FriendProfileTheme.buttonRadius),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.04),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DestructiveTextAction extends StatelessWidget {
  const _DestructiveTextAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: FriendProfileTheme.destructive),
        label: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: FriendProfileTheme.destructive,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
