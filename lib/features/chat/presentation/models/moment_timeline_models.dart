import 'package:equatable/equatable.dart';

enum MomentSpaceTab { moments, media, shared, about }

enum MomentTimelineKind { media, thought, photo, voice, shared }

class MomentReactionSummary extends Equatable {
  const MomentReactionSummary({required this.emoji, this.count = 0});

  final String emoji;
  final int count;

  @override
  List<Object?> get props => [emoji, count];
}

class MomentReplyPreview extends Equatable {
  const MomentReplyPreview({
    required this.senderName,
    required this.body,
    required this.isMine,
  });

  final String senderName;
  final String body;
  final bool isMine;

  @override
  List<Object?> get props => [senderName, body, isMine];
}

class MomentTimelineEntry extends Equatable {
  const MomentTimelineEntry({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.isMine,
    this.title,
    this.body,
    this.subtitle,
    this.location,
    this.mediaUrl,
    this.duration,
    this.overlayLabel,
    this.reactions = const [],
    this.replyPreview,
    this.isDeleted = false,
    this.isRead = false,
  });

  final String id;
  final MomentTimelineKind kind;
  final DateTime createdAt;
  final bool isMine;
  final String? title;
  final String? body;
  final String? subtitle;
  final String? location;
  final String? mediaUrl;
  final String? duration;
  final String? overlayLabel;
  final List<MomentReactionSummary> reactions;
  final MomentReplyPreview? replyPreview;
  final bool isDeleted;
  final bool isRead;

  bool get hasMedia =>
      kind == MomentTimelineKind.media || kind == MomentTimelineKind.photo;

  @override
  List<Object?> get props => [
        id,
        kind,
        createdAt,
        isMine,
        title,
        body,
        subtitle,
        location,
        mediaUrl,
        duration,
        overlayLabel,
        reactions,
        replyPreview,
        isDeleted,
        isRead,
      ];
}

/// Groups timeline rows: date headers + entries.
sealed class MomentTimelineRow extends Equatable {
  const MomentTimelineRow();
}

class MomentTimelineDateRow extends MomentTimelineRow {
  const MomentTimelineDateRow(this.label);

  final String label;

  @override
  List<Object?> get props => [label];
}

class MomentTimelineEntryRow extends MomentTimelineRow {
  const MomentTimelineEntryRow(this.entry);

  final MomentTimelineEntry entry;

  @override
  List<Object?> get props => [entry];
}
