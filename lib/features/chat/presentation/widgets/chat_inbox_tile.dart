import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/features/chat/presentation/theme/chat_typography.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/presentation/utils/chat_formatters.dart';

class ChatInboxTile extends StatelessWidget {
  const ChatInboxTile({
    required this.conversation,
    this.isTyping = false,
    super.key,
  });

  final ChatConversation conversation;
  final bool isTyping;

  @override
  Widget build(BuildContext context) {
    final user = conversation.otherUser;
    final hasUnread = conversation.unreadCount > 0;
    final preview = conversation.lastMessagePreview?.trim();
    final timeLabel = conversation.lastMessageAt == null
        ? ''
        : ChatFormatters.inboxTime(conversation.lastMessageAt!);
    final firstName = user.displayName.split(' ').first;
    final isPinned = conversation.isPinned;

    return Container(
      decoration: isPinned
          ? BoxDecoration(
              color: context.mc.surface.withValues(alpha: 0.35),
              border: Border(
                left: BorderSide(
                  color: ChatTheme.accent(context).withValues(alpha: 0.7),
                  width: 3,
                ),
              ),
            )
          : null,
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MomentAvatar(
            name: user.displayName,
            imageUrl: user.avatarUrl,
            size: 52,
            showBorder: hasUnread,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChatTypography.inboxName(unread: hasUnread),
                ),
                const SizedBox(height: 3),
                isTyping
                    ? Text(
                        '$firstName is typing...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ChatTypography.inboxPreview(
                          unread: true,
                          color: ChatTheme.accentPink(context),
                        ).copyWith(fontStyle: FontStyle.italic),
                      )
                    : Text(
                        preview?.isNotEmpty == true ? preview! : 'Say hi 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ChatTypography.inboxPreview(
                          unread: hasUnread,
                          color: hasUnread
                              ? context.mc.textSecondary
                              : ChatTheme.tertiaryText(context),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (timeLabel.isNotEmpty)
                Text(
                  timeLabel,
                  style: ChatTypography.inboxTime(
                    color: hasUnread
                        ? ChatTheme.accentPink(context)
                        : ChatTheme.tertiaryText(context),
                  ),
                ),
              const SizedBox(height: 6),
              _TrailingStatus(
                hasUnread: hasUnread && !isTyping,
                unreadCount: conversation.unreadCount,
                isMuted: conversation.isMuted,
                isPinned: isPinned,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrailingStatus extends StatelessWidget {
  const _TrailingStatus({
    required this.hasUnread,
    required this.unreadCount,
    required this.isMuted,
    required this.isPinned,
  });

  final bool hasUnread;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    if (hasUnread) {
      return Container(
        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: ChatTheme.accentPink(context),
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          unreadCount > 9 ? '9+' : '$unreadCount',
          style: ChatTypography.inboxTime(color: Colors.white).copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      );
    }

    if (isMuted) {
      return Icon(
        Icons.notifications_off_outlined,
        size: 16,
        color: ChatTheme.tertiaryText(context),
      );
    }

    if (isPinned) {
      return Icon(
        Icons.push_pin_rounded,
        size: 15,
        color: ChatTheme.tertiaryText(context),
      );
    }

    return const SizedBox(width: 22, height: 22);
  }
}

class ChatSectionHeader extends StatelessWidget {
  const ChatSectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: ChatTypography.inboxTime(
          color: ChatTheme.tertiaryText(context),
        ).copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          fontSize: 11,
        ),
      ),
    );
  }
}
