import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';
import 'package:moment/features/chat/presentation/utils/chat_formatters.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.message,
    required this.mediaUrl,
    required this.showAvatar,
    required this.showTimestamp,
    required this.isFirstInGroup,
    this.otherUser,
    this.animate = false,
    super.key,
  });

  final ChatMessage message;
  final String? mediaUrl;
  final bool showAvatar;
  final bool showTimestamp;
  final bool isFirstInGroup;
  final UserProfile? otherUser;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final topPad = isFirstInGroup ? 10.0 : 2.0;

    final row = Padding(
      padding: EdgeInsets.only(top: topPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            SizedBox(
              width: 28,
              child: showAvatar && otherUser != null
                  ? MomentAvatar(
                      name: otherUser!.displayName,
                      imageUrl: otherUser!.avatarUrl,
                      size: 26,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: message.body.isNotEmpty
                  ? () => _copyMessage(context, message.body)
                  : null,
              child: _BubbleBody(
                message: message,
                mediaUrl: mediaUrl,
                isMine: isMine,
                showTimestamp: showTimestamp,
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 4),
        ],
      ),
    );

    if (!animate) return row;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 6),
            child: child,
          ),
        );
      },
      child: row,
    );
  }

  void _copyMessage(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({
    required this.message,
    required this.mediaUrl,
    required this.isMine,
    required this.showTimestamp,
  });

  final ChatMessage message;
  final String? mediaUrl;
  final bool isMine;
  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    if (message.messageType == ChatMessageType.image && mediaUrl != null) {
      return _ImageBubble(
        mediaUrl: mediaUrl!,
        isMine: isMine,
        showTimestamp: showTimestamp,
        createdAt: message.createdAt,
        isRead: message.isRead,
      );
    }

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );

    final bubbleColor = isMine
        ? ChatTheme.sentBubble(context)
        : ChatTheme.receivedBubble(context);

    final textColor = isMine
        ? Colors.white
        : ChatTheme.primaryText(context);

    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: radius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(
          message.body,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: textColor,
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );

    if (!showTimestamp) return bubble;

    return Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        bubble,
        const SizedBox(height: 3),
        _TimestampRow(
          time: message.createdAt,
          isMine: isMine,
          isRead: message.isRead,
        ),
      ],
    );
  }
}

class _ImageBubble extends StatelessWidget {
  const _ImageBubble({
    required this.mediaUrl,
    required this.isMine,
    required this.showTimestamp,
    required this.createdAt,
    required this.isRead,
  });

  final String mediaUrl;
  final bool isMine;
  final bool showTimestamp;
  final DateTime createdAt;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: mediaUrl,
            width: 220,
            height: 160,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              width: 220,
              height: 160,
              color: ChatTheme.receivedBubble(context),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ChatTheme.tertiaryText(context),
                ),
              ),
            ),
            errorWidget: (_, _, _) => Container(
              width: 220,
              height: 120,
              color: ChatTheme.receivedBubble(context),
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_outlined,
                color: ChatTheme.tertiaryText(context).withValues(alpha: 0.7),
              ),
            ),
          ),
          if (showTimestamp)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ChatFormatters.messageTime(createdAt),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 3),
                      Icon(
                        isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimestampRow extends StatelessWidget {
  const _TimestampRow({
    required this.time,
    required this.isMine,
    required this.isRead,
  });

  final DateTime time;
  final bool isMine;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ChatFormatters.messageTime(time),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: ChatTheme.tertiaryText(context),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: 3),
          Icon(
            isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: 13,
            color: ChatTheme.readReceipt,
          ),
        ],
      ],
    );
  }
}
