import 'package:flutter/material.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/features/chat/data/chat_media_resolver.dart';
import 'package:moment/features/chat/presentation/models/moment_timeline_models.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';
import 'package:moment/features/chat/presentation/widgets/moment_space/moment_timeline_cards.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class MomentSpaceTimeline extends StatefulWidget {
  const MomentSpaceTimeline({
    required this.rows,
    required this.otherUser,
    required this.scrollController,
    this.onAddReaction,
    this.onMomentMenu,
    this.onLongPress,
    this.onReply,
    super.key,
  });

  final List<MomentTimelineRow> rows;
  final UserProfile otherUser;
  final ScrollController scrollController;
  final void Function(MomentTimelineEntry entry)? onAddReaction;
  final void Function(MomentTimelineEntry entry)? onMomentMenu;
  final void Function(MomentTimelineEntry entry)? onLongPress;
  final void Function(MomentTimelineEntry entry)? onReply;

  @override
  State<MomentSpaceTimeline> createState() => _MomentSpaceTimelineState();
}

class _MomentSpaceTimelineState extends State<MomentSpaceTimeline> {
  final _resolver = sl<ChatMediaResolver>();
  final Map<String, String?> _mediaUrls = {};

  @override
  void didUpdateWidget(MomentSpaceTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveMedia();
  }

  @override
  void initState() {
    super.initState();
    _resolveMedia();
  }

  Future<void> _resolveMedia() async {
    final activeIds = <String>{};
    for (final row in widget.rows) {
      if (row is! MomentTimelineEntryRow) continue;
      final entry = row.entry;
      activeIds.add(entry.id);

      if (entry.isDeleted || entry.mediaUrl == null || entry.mediaUrl!.isEmpty) {
        _mediaUrls.remove(entry.id);
        continue;
      }

      if (_mediaUrls.containsKey(entry.id)) continue;

      final url = await _resolver.resolve(entry.mediaUrl);
      if (!mounted) return;
      setState(() => _mediaUrls[entry.id] = url);
    }

    _mediaUrls.removeWhere((id, _) => !activeIds.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return _EmptyTimeline(otherUser: widget.otherUser);
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: widget.rows.length,
      itemBuilder: (context, index) {
        final row = widget.rows[index];
        return switch (row) {
          MomentTimelineDateRow(:final label) =>
            MomentTimelineDateDivider(label: label),
          MomentTimelineEntryRow(:final entry) => _TimelineItem(
              entry: entry,
              otherUser: widget.otherUser,
              mediaUrl: entry.isDeleted || entry.mediaUrl == null
                  ? null
                  : _mediaUrls[entry.id],
              onAddReaction: () => widget.onAddReaction?.call(entry),
              onMenu: () => widget.onMomentMenu?.call(entry),
              onLongPress: () => widget.onLongPress?.call(entry),
              onReply: () => widget.onReply?.call(entry),
            ),
        };
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.entry,
    required this.otherUser,
    this.mediaUrl,
    this.onAddReaction,
    this.onMenu,
    this.onLongPress,
    this.onReply,
  });

  final MomentTimelineEntry entry;
  final UserProfile otherUser;
  final String? mediaUrl;
  final VoidCallback? onAddReaction;
  final VoidCallback? onMenu;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final card = MomentTimelineCard(
      entry: entry,
      otherUser: otherUser,
      mediaUrl: mediaUrl,
      onMenu: onMenu,
      onAddReaction: onAddReaction,
      onLongPress: onLongPress,
      onReply: onReply,
    );

    if (entry.isMine) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 52),
        child: Align(
          alignment: Alignment.centerRight,
          child: card,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 52),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MomentAvatar(
            name: otherUser.displayName,
            imageUrl: otherUser.avatarUrl,
            size: 32,
          ),
          const SizedBox(width: 8),
          Flexible(child: card),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline({required this.otherUser});

  final UserProfile otherUser;

  @override
  Widget build(BuildContext context) {
    final firstName = otherUser.displayName.split(' ').first;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MomentAvatar(
              name: otherUser.displayName,
              imageUrl: otherUser.avatarUrl,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              'Start chatting with $firstName',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: MomentSpaceTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to begin your conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: MomentSpaceTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
