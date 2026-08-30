import 'package:flutter/material.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/features/chat/presentation/theme/chat_typography.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/presentation/utils/chat_formatters.dart';

class ChatInboxTile extends StatelessWidget {
  const ChatInboxTile({
    required this.conversation,
    required this.onTap,
    this.onLongPress,
    this.isTyping = false,
    super.key,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MomentAvatar(
                name: user.displayName,
                imageUrl: user.avatarUrl,
                size: 50,
                showBorder: hasUnread,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ChatTypography.inboxName(
                              unread: hasUnread,
                            ),
                          ),
                        ),
                        if (timeLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          if (conversation.isPinned) ...[
                            Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: ChatTheme.tertiaryText,
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (conversation.isMuted) ...[
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 14,
                              color: ChatTheme.tertiaryText,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            timeLabel,
                            style: ChatTypography.inboxTime(
                              color: hasUnread
                                  ? ChatTheme.accentPink
                                  : ChatTheme.tertiaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: isTyping
                              ? Text(
                                  '$firstName is typing...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ChatTypography.inboxPreview(
                                    unread: true,
                                    color: ChatTheme.accentPink,
                                  ).copyWith(fontStyle: FontStyle.italic),
                                )
                              : Text(
                                  preview?.isNotEmpty == true
                                      ? preview!
                                      : 'Say hi 👋',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ChatTypography.inboxPreview(
                                    unread: hasUnread,
                                    color: hasUnread
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : ChatTheme.tertiaryText,
                                  ),
                                ),
                        ),
                        if (hasUnread && !isTyping) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ChatTheme.accentPink,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              conversation.unreadCount > 9
                                  ? '9+'
                                  : '${conversation.unreadCount}',
                              style: ChatTypography.inboxTime(
                                color: Colors.white,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatSectionHeader extends StatelessWidget {
  const ChatSectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: ChatTypography.inboxSubtitle(color: ChatTheme.tertiaryText)
            .copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
