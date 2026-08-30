import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/presentation/theme/chat_typography.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';

enum ChatInboxMenuAction {
  viewProfile,
  pin,
  unpin,
  mute,
  unmute,
  deleteChat,
  block,
  unblock,
}

Future<ChatInboxMenuAction?> showChatInboxMenu(
  BuildContext context,
  ChatConversation conversation, {
  required FriendRelationship relationship,
}) {
  final isBlockedByMe = relationship == FriendRelationship.blocked;
  final isPinned = conversation.isPinned;
  final isMuted = conversation.isMuted;

  return showModalBottomSheet<ChatInboxMenuAction>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuTile(
                icon: Icons.person_outline_rounded,
                label: 'View profile',
                onTap: () =>
                    Navigator.pop(context, ChatInboxMenuAction.viewProfile),
              ),
              _MenuTile(
                icon: isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                label: isPinned ? 'Unpin chat' : 'Pin chat',
                onTap: () => Navigator.pop(
                  context,
                  isPinned ? ChatInboxMenuAction.unpin : ChatInboxMenuAction.pin,
                ),
              ),
              _MenuTile(
                icon: isMuted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                label: isMuted ? 'Unmute messages' : 'Mute messages',
                onTap: () => Navigator.pop(
                  context,
                  isMuted ? ChatInboxMenuAction.unmute : ChatInboxMenuAction.mute,
                ),
              ),
              _MenuTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete chat',
                destructive: true,
                onTap: () =>
                    Navigator.pop(context, ChatInboxMenuAction.deleteChat),
              ),
              _MenuTile(
                icon: isBlockedByMe
                    ? Icons.lock_open_rounded
                    : Icons.block_rounded,
                label: isBlockedByMe ? 'Unblock' : 'Block',
                destructive: !isBlockedByMe,
                onTap: () => Navigator.pop(
                  context,
                  isBlockedByMe
                      ? ChatInboxMenuAction.unblock
                      : ChatInboxMenuAction.block,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFFF6B6B)
        : AppColors.textPrimaryDark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      minVerticalPadding: 14,
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        label,
        style: ChatTypography.inboxSheetAction(color: color),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
