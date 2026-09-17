import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/chat/presentation/models/moment_timeline_models.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';
import 'package:moment/features/chat/presentation/utils/chat_formatters.dart';
import 'package:moment/features/chat/presentation/theme/chat_typography.dart';
import 'package:moment/features/chat/presentation/widgets/chat_message_quote.dart';
import 'package:moment/features/chat/presentation/widgets/chat_swipe_to_reply.dart';
import 'package:moment/features/chat/presentation/widgets/message_reaction_chip.dart';
import 'package:moment/features/chat/presentation/widgets/moment_space/moment_reaction_bar.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class MomentTimelineDateDivider extends StatelessWidget {
  const MomentTimelineDateDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Container(
      height: 1,
      color: MomentSpaceTheme.timelineLine(context).withValues(alpha: 0.8),
    );
    final text = Text(
      label,
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: MomentSpaceTheme.textTertiary(context),
        letterSpacing: 0.2,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: line),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: text,
          ),
          Expanded(child: line),
        ],
      ),
    );
  }
}

class MomentTimelineCard extends StatelessWidget {
  const MomentTimelineCard({
    required this.entry,
    required this.otherUser,
    this.mediaUrl,
    this.onMenu,
    this.onAddReaction,
    this.onLongPress,
    this.onReply,
    this.onPlay,
    super.key,
  });

  final MomentTimelineEntry entry;
  final UserProfile otherUser;
  final String? mediaUrl;
  final VoidCallback? onMenu;
  final VoidCallback? onAddReaction;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return switch (entry.kind) {
      MomentTimelineKind.media => _MediaMomentCard(
          entry: entry,
          mediaUrl: mediaUrl,
          onMenu: onMenu,
          onAddReaction: onAddReaction,
          onPlay: onPlay,
        ),
      MomentTimelineKind.thought => _ThoughtMomentCard(
          entry: entry,
          otherUser: otherUser,
          onMenu: onMenu,
          onAddReaction: onAddReaction,
          onLongPress: onLongPress,
          onReply: onReply,
        ),
      MomentTimelineKind.photo => _PhotoMomentCard(
          entry: entry,
          mediaUrl: mediaUrl,
          onAddReaction: onAddReaction,
          onLongPress: onLongPress,
          onReply: onReply,
        ),
      MomentTimelineKind.voice => _VoiceMomentCard(
          entry: entry,
          otherUser: otherUser,
          onMenu: onMenu,
          onAddReaction: onAddReaction,
          onPlay: onPlay,
        ),
      MomentTimelineKind.shared => _SharedMomentCard(
          entry: entry,
          otherUser: otherUser,
        ),
    };
  }
}

class _CardMenu extends StatelessWidget {
  const _CardMenu({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 18,
        color: MomentSpaceTheme.textTertiary(context),
      ),
      onPressed: onTap,
    );
  }
}

class _MediaMomentCard extends StatelessWidget {
  const _MediaMomentCard({
    required this.entry,
    this.mediaUrl,
    this.onMenu,
    this.onAddReaction,
    this.onPlay,
  });

  final MomentTimelineEntry entry;
  final String? mediaUrl;
  final VoidCallback? onMenu;
  final VoidCallback? onAddReaction;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: MomentSpaceTheme.cardDecoration(context),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MediaThumb(
                    mediaUrl: mediaUrl,
                    duration: entry.duration ?? '0:24',
                    onPlay: onPlay,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.body ?? '',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: MomentSpaceTheme.textPrimary(context),
                            height: 1.4,
                          ),
                        ),
                        if (entry.location != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: MomentSpaceTheme.textTertiary(context),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                entry.location!,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 11,
                                  color: MomentSpaceTheme.textTertiary(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  _CardMenu(onTap: onMenu),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _fullTimestamp(entry.createdAt),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10,
                  color: MomentSpaceTheme.textTertiary(context),
                ),
              ),
            ],
          ),
        ),
        MomentReactionBar(
          reactions: entry.reactions,
          onAddReaction: onAddReaction,
        ),
      ],
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({
    this.mediaUrl,
    required this.duration,
    this.onPlay,
  });

  final String? mediaUrl;
  final String duration;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 72,
          height: 52,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (mediaUrl != null)
                CachedNetworkImage(imageUrl: mediaUrl!, fit: BoxFit.cover)
              else
                Container(color: MomentSpaceTheme.surfaceElevated(context)),
              Container(color: Colors.black.withValues(alpha: 0.25)),
              Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 16),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 4,
                child: Text(
                  duration,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThoughtMomentCard extends StatelessWidget {
  const _ThoughtMomentCard({
    required this.entry,
    required this.otherUser,
    this.onMenu,
    this.onAddReaction,
    this.onLongPress,
    this.onReply,
  });

  final MomentTimelineEntry entry;
  final UserProfile otherUser;
  final VoidCallback? onMenu;
  final VoidCallback? onAddReaction;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    if (entry.isMine) {
      return _MineTextCard(
        entry: entry,
        onLongPress: onLongPress,
        onReply: onReply,
        onAddReaction: onAddReaction,
      );
    }

    return ChatSwipeToReply(
      onReply: onReply ?? () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MessageBubbleWithReactions(
            bubble: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: MomentSpaceTheme.theirsBubbleDecoration(context),
                child: _BubbleContent(entry: entry, isMineBubble: false),
              ),
            ),
            reactions: entry.reactions,
            isMine: false,
            onReactionTap: onAddReaction,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _MessageMetaRow(entry: entry),
          ),
        ],
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({
    required this.entry,
    required this.isMineBubble,
  });

  final MomentTimelineEntry entry;
  final bool isMineBubble;

  @override
  Widget build(BuildContext context) {
    final textStyle = entry.isDeleted
        ? ChatTypography.bubbleBody(
            isMine: isMineBubble,
            color: isMineBubble
                ? Colors.white.withValues(alpha: 0.7)
                : MomentSpaceTheme.textTertiary(context),
          ).copyWith(fontStyle: FontStyle.italic, fontSize: 14)
        : ChatTypography.bubbleBody(
            isMine: isMineBubble,
            color: isMineBubble
                ? Colors.white
                : MomentSpaceTheme.textPrimary(context),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.replyPreview != null)
          ChatMessageQuote(
            reply: entry.replyPreview!,
            isMineBubble: isMineBubble,
          ),
        Text(entry.body ?? '', style: textStyle),
      ],
    );
  }
}

class _MineTextCard extends StatelessWidget {
  const _MineTextCard({
    required this.entry,
    this.onLongPress,
    this.onReply,
    this.onAddReaction,
  });

  final MomentTimelineEntry entry;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;
  final VoidCallback? onAddReaction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = (constraints.maxWidth * 0.8).clamp(160.0, 300.0);

        return Align(
          alignment: Alignment.centerRight,
          child: ChatSwipeToReply(
            onReply: onReply ?? () {},
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: MessageBubbleWithReactions(
                      bubble: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration:
                            MomentSpaceTheme.mineBubbleDecoration(context),
                        child: _BubbleContent(entry: entry, isMineBubble: true),
                      ),
                      reactions: entry.reactions,
                      isMine: true,
                      onReactionTap: onAddReaction,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _MessageMetaRow(entry: entry),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhotoMomentCard extends StatelessWidget {
  const _PhotoMomentCard({
    required this.entry,
    this.mediaUrl,
    this.onAddReaction,
    this.onLongPress,
    this.onReply,
  });

  final MomentTimelineEntry entry;
  final String? mediaUrl;
  final VoidCallback? onAddReaction;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final imageWidth =
        (MediaQuery.sizeOf(context).width * 0.68).clamp(180.0, 280.0);

    final photo = GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: imageWidth,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MomentSpaceTheme.cardRadius),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (mediaUrl != null)
                CachedNetworkImage(
                  imageUrl: mediaUrl!,
                  width: imageWidth,
                  fit: BoxFit.fitWidth,
                  placeholder: (_, _) => AspectRatio(
                    aspectRatio: 1,
                    child: ColoredBox(
                      color: MomentSpaceTheme.surfaceElevated(context),
                    ),
                  ),
                  errorWidget: (_, _, _) => AspectRatio(
                    aspectRatio: 1,
                    child: ColoredBox(
                      color: MomentSpaceTheme.surfaceElevated(context),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: MomentSpaceTheme.textTertiary(context),
                      ),
                    ),
                  ),
                )
              else
                AspectRatio(
                  aspectRatio: 1,
                  child: ColoredBox(
                    color: MomentSpaceTheme.surfaceElevated(context),
                  ),
                ),
              if (entry.overlayLabel != null)
                Positioned(
                  left: 12,
                  top: 12,
                  right: 12,
                  child: Text(
                    entry.overlayLabel!,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                right: 12,
                bottom: 10,
                child: _ReadMeta(
                  time: entry.createdAt,
                  isMine: entry.isMine,
                  isRead: entry.isRead,
                  isStarred: entry.isStarred,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment:
          entry.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (onReply != null)
          ChatSwipeToReply(onReply: onReply!, child: photo)
        else
          photo,
        MomentReactionBar(
          reactions: entry.reactions,
          onAddReaction: onAddReaction,
        ),
      ],
    );
  }
}

class _VoiceMomentCard extends StatelessWidget {
  const _VoiceMomentCard({
    required this.entry,
    required this.otherUser,
    this.onMenu,
    this.onAddReaction,
    this.onPlay,
  });

  final MomentTimelineEntry entry;
  final UserProfile otherUser;
  final VoidCallback? onMenu;
  final VoidCallback? onAddReaction;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: MomentSpaceTheme.cardDecoration(context),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onPlay,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: MomentSpaceTheme.accentGradient(
                                context,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WaveformBar(color: context.mc.accent),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.duration ?? '0:18',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: MomentSpaceTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CardMenu(onTap: onMenu),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  ChatFormatters.messageTime(entry.createdAt),
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10,
                    color: MomentSpaceTheme.textTertiary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        MomentReactionBar(
          reactions: entry.reactions,
          onAddReaction: onAddReaction,
        ),
      ],
    );
  }
}

class _WaveformBar extends StatelessWidget {
  const _WaveformBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const heights = [0.35, 0.55, 0.8, 0.45, 0.9, 0.5, 0.7, 0.4, 0.85, 0.6];
    return SizedBox(
      height: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final h in heights) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                height: 28 * h,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SharedMomentCard extends StatelessWidget {
  const _SharedMomentCard({
    required this.entry,
    required this.otherUser,
  });

  final MomentTimelineEntry entry;
  final UserProfile otherUser;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * 0.72).clamp(160.0, 240.0);

        return Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: cardWidth,
                child: Container(
                  decoration: MomentSpaceTheme.cardDecoration(
                    context,
                    gradient: MomentSpaceTheme.accentGradient(context),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title ?? 'You shared a moment',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            Text(
                              entry.body ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              _MessageMetaRow(
                entry: entry,
                timeStyle: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 9,
                  color: MomentSpaceTheme.textTertiary(context),
                ),
                iconSize: 11,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageMetaRow extends StatelessWidget {
  const _MessageMetaRow({
    required this.entry,
    this.timeStyle,
    this.iconSize = 12,
  });

  final MomentTimelineEntry entry;
  final TextStyle? timeStyle;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entry.isStarred) ...[
          Icon(
            Icons.star_rounded,
            size: iconSize,
            color: const Color(0xFFFFB020),
          ),
          const SizedBox(width: 3),
        ],
        if (entry.isEdited) ...[
          Text(
            'Edited',
            style: timeStyle ??
                ChatTypography.bubbleMeta(
                  color: MomentSpaceTheme.textTertiary(context),
                ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          ChatFormatters.messageTime(entry.createdAt),
          style: timeStyle ??
              ChatTypography.bubbleMeta(
                color: MomentSpaceTheme.textTertiary(context),
              ),
        ),
        if (entry.isMine) ...[
          const SizedBox(width: 4),
          Icon(
            entry.isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: iconSize,
            color: entry.isRead
                ? MomentSpaceTheme.readBlue
                : MomentSpaceTheme.textTertiary(context),
          ),
        ],
      ],
    );
  }
}

class _ReadMeta extends StatelessWidget {
  const _ReadMeta({
    required this.time,
    required this.isMine,
    required this.isRead,
    this.isStarred = false,
  });

  final DateTime time;
  final bool isMine;
  final bool isRead;
  final bool isStarred;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isStarred) ...[
          const Icon(
            Icons.star_rounded,
            size: 12,
            color: Color(0xFFFFB020),
          ),
          const SizedBox(width: 3),
        ],
        Text(
          ChatFormatters.messageTime(time),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: 4),
          Icon(
            isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: 12,
            color: isRead
                ? MomentSpaceTheme.readBlue
                : Colors.white.withValues(alpha: 0.85),
          ),
        ],
      ],
    );
  }
}

String _fullTimestamp(DateTime time) {
  final label = ChatFormatters.dateDivider(time);
  return '$label • ${ChatFormatters.messageTime(time)}';
}
