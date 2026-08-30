import 'package:flutter/material.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/chat/data/chat_media_resolver.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/presentation/utils/chat_formatters.dart';
import 'package:moment/features/chat/presentation/widgets/chat_date_divider.dart';
import 'package:moment/features/chat/presentation/widgets/chat_encryption_banner.dart';
import 'package:moment/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class _MessageRow {
  const _MessageRow({
    required this.message,
    required this.showAvatar,
    required this.showTimestamp,
    required this.isFirstInGroup,
    required this.animate,
  });

  final ChatMessage message;
  final bool showAvatar;
  final bool showTimestamp;
  final bool isFirstInGroup;
  final bool animate;
}

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    required this.messages,
    required this.scrollController,
    required this.otherUser,
    this.lastAnimatedId,
    this.showEncryptionBanner = true,
    super.key,
  });

  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final UserProfile otherUser;
  final String? lastAnimatedId;
  final bool showEncryptionBanner;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final _resolver = sl<ChatMediaResolver>();
  final Map<String, String?> _mediaUrls = {};

  static const _groupGap = Duration(minutes: 2);

  List<({_MessageRow? message, DateTime? date})> get _rows {
    final sorted = ChatFormatters.chronological(widget.messages);
    final rows = <({_MessageRow? message, DateTime? date})>[];

    for (var i = 0; i < sorted.length; i++) {
      final message = sorted[i];
      if (i == 0 ||
          !ChatFormatters.isSameDay(
            sorted[i - 1].createdAt,
            message.createdAt,
          )) {
        rows.add((message: null, date: message.createdAt));
      }

      final prev = i > 0 ? sorted[i - 1] : null;
      final next = i < sorted.length - 1 ? sorted[i + 1] : null;

      final groupsWithPrev = prev != null &&
          prev.senderId == message.senderId &&
          message.createdAt.difference(prev.createdAt) <= _groupGap;

      final groupsWithNext = next != null &&
          next.senderId == message.senderId &&
          next.createdAt.difference(message.createdAt) <= _groupGap;

      rows.add((
        message: _MessageRow(
          message: message,
          showAvatar: !message.isMine && !groupsWithNext,
          showTimestamp: !groupsWithNext,
          isFirstInGroup: !groupsWithPrev,
          animate: message.id == widget.lastAnimatedId,
        ),
        date: null,
      ));
    }
    return rows;
  }

  @override
  void didUpdateWidget(ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveMedia(widget.messages);
  }

  @override
  void initState() {
    super.initState();
    _resolveMedia(widget.messages);
  }

  Future<void> _resolveMedia(List<ChatMessage> messages) async {
    for (final message in messages) {
      final path = message.mediaUrl;
      if (path == null || path.isEmpty || _mediaUrls.containsKey(message.id)) {
        continue;
      }
      final url = await _resolver.resolve(path);
      if (!mounted) return;
      setState(() => _mediaUrls[message.id] = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final bannerExtra = widget.showEncryptionBanner ? 1 : 0;

    return ListView.builder(
      controller: widget.scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      itemCount: rows.length + bannerExtra,
      itemBuilder: (context, index) {
        if (widget.showEncryptionBanner && index == rows.length) {
          return const ChatEncryptionBanner();
        }

        final row = rows[rows.length - 1 - index];
        if (row.date != null) {
          return ChatDateDivider(
            label: ChatFormatters.dateDivider(row.date!),
          );
        }
        final item = row.message!;
        return ChatMessageBubble(
          message: item.message,
          mediaUrl: _mediaUrls[item.message.id],
          showAvatar: item.showAvatar,
          showTimestamp: item.showTimestamp,
          isFirstInGroup: item.isFirstInGroup,
          otherUser: widget.otherUser,
          animate: item.animate,
        );
      },
    );
  }
}
