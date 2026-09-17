import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/presentation/models/moment_timeline_models.dart';
import 'package:moment/features/chat/presentation/utils/chat_formatters.dart';

abstract final class MomentTimelineMapper {
  static List<MomentTimelineRow> buildRows({
    required List<ChatMessage> messages,
    required MomentSpaceTab tab,
    required String otherUserName,
    required String currentUserId,
  }) {
    final entries = _mapMessages(
      messages,
      otherUserName: otherUserName,
      currentUserId: currentUserId,
    )
        .where((entry) => _matchesTab(entry, tab))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final rows = <MomentTimelineRow>[];
    DateTime? lastDay;

    for (final entry in entries) {
      final day = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      if (lastDay == null || day != lastDay) {
        rows.add(MomentTimelineDateRow(_dateLabel(entry.createdAt)));
        lastDay = day;
      }
      rows.add(MomentTimelineEntryRow(entry));
    }

    return rows;
  }

  static bool _matchesTab(MomentTimelineEntry entry, MomentSpaceTab tab) {
    return switch (tab) {
      MomentSpaceTab.moments => true,
      MomentSpaceTab.media => entry.hasMedia,
      MomentSpaceTab.shared => entry.isMine,
      MomentSpaceTab.about => false,
    };
  }

  static List<MomentTimelineEntry> _mapMessages(
    List<ChatMessage> messages, {
    required String otherUserName,
    required String currentUserId,
  }) {
    return messages.map((message) {
      final reactions = _reactionSummaries(message.reactions);
      final replyPreview = _replyPreview(
        message,
        otherUserName: otherUserName,
        currentUserId: currentUserId,
      );
      final body = message.deletedForEveryone
          ? 'This message was deleted'
          : message.body;

      switch (message.messageType) {
        case ChatMessageType.image:
          if (message.deletedForEveryone) {
            return MomentTimelineEntry(
              id: message.id,
              kind: MomentTimelineKind.thought,
              createdAt: message.createdAt,
              isMine: message.isMine,
              body: body,
              reactions: reactions,
              replyPreview: replyPreview,
              isDeleted: true,
              isRead: message.isRead,
              isStarred: message.isStarred,
              isEdited: message.editedAt != null,
            );
          }
          final caption = _imageCaption(message.body);
          return MomentTimelineEntry(
            id: message.id,
            kind: MomentTimelineKind.photo,
            createdAt: message.createdAt,
            isMine: message.isMine,
            body: caption,
            overlayLabel: caption,
            mediaUrl: message.mediaUrl,
            reactions: reactions,
            replyPreview: replyPreview,
            isDeleted: false,
            isRead: message.isRead,
            isStarred: message.isStarred,
            isEdited: message.editedAt != null,
          );
        case ChatMessageType.snap:
          return MomentTimelineEntry(
            id: message.id,
            kind: MomentTimelineKind.media,
            createdAt: message.createdAt,
            isMine: message.isMine,
            body: message.deletedForEveryone
                ? body
                : (message.body.trim().isNotEmpty ? message.body : 'Shared a moment'),
            mediaUrl: message.deletedForEveryone ? null : message.mediaUrl,
            duration: null,
            reactions: reactions,
            replyPreview: replyPreview,
            isDeleted: message.deletedForEveryone,
            isRead: message.isRead,
            isStarred: message.isStarred,
            isEdited: message.editedAt != null,
          );
        case ChatMessageType.text:
          return MomentTimelineEntry(
            id: message.id,
            kind: MomentTimelineKind.thought,
            createdAt: message.createdAt,
            isMine: message.isMine,
            body: body,
            reactions: reactions,
            replyPreview: replyPreview,
            isDeleted: message.deletedForEveryone,
            isRead: message.isRead,
            isStarred: message.isStarred,
            isEdited: message.editedAt != null,
          );
      }
    }).toList();
  }

  static List<MomentReactionSummary> _reactionSummaries(
    List<ChatMessageReaction> reactions,
  ) {
    final counts = <String, int>{};
    for (final reaction in reactions) {
      counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
    }
    return counts.entries
        .map(
          (entry) => MomentReactionSummary(
            emoji: entry.key,
            count: entry.value,
          ),
        )
        .toList();
  }

  static MomentReplyPreview? _replyPreview(
    ChatMessage message, {
    required String otherUserName,
    required String currentUserId,
  }) {
    final reply = message.replyTo;
    if (reply == null) return null;

    final replyIsMine = reply.senderId == currentUserId;
    final senderName = replyIsMine ? 'You' : otherUserName;

    if (reply.deletedForEveryone) {
      return MomentReplyPreview(
        senderName: senderName,
        body: 'This message was deleted',
        isMine: replyIsMine,
      );
    }

    final preview = switch (reply.messageType) {
      ChatMessageType.image =>
        _imageCaption(reply.body) ?? 'Photo',
      ChatMessageType.snap => 'Shared a moment',
      ChatMessageType.text => reply.body,
    };

    return MomentReplyPreview(
      senderName: senderName,
      body: preview,
      isMine: replyIsMine,
    );
  }

  static String? _imageCaption(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == 'Photo') return null;
    return trimmed;
  }

  static String _dateLabel(DateTime time) {
    final now = DateTime.now();
    final local = time.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return ChatFormatters.dateDivider(time);
  }
}
