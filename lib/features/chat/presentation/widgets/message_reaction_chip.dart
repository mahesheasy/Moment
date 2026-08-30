import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/features/chat/presentation/models/moment_timeline_models.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';

/// WhatsApp-style reaction pill attached to the message bubble corner.
class MessageReactionChip extends StatelessWidget {
  const MessageReactionChip({
    required this.reactions,
    required this.isMine,
    this.onTap,
    super.key,
  });

  final List<MomentReactionSummary> reactions;
  final bool isMine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visible = reactions.where((r) => r.count > 0).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final total = visible.fold<int>(0, (sum, r) => sum + r.count);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: MomentSpaceTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: MomentSpaceTheme.border(context),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < visible.length && i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 1),
              Text(visible[i].emoji, style: const TextStyle(fontSize: 13)),
            ],
            if (total > 1) ...[
              const SizedBox(width: 4),
              Text(
                '$total',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MomentSpaceTheme.textSecondary(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wraps a bubble with corner-attached reactions.
class MessageBubbleWithReactions extends StatelessWidget {
  const MessageBubbleWithReactions({
    required this.bubble,
    required this.reactions,
    required this.isMine,
    this.onReactionTap,
    super.key,
  });

  final Widget bubble;
  final List<MomentReactionSummary> reactions;
  final bool isMine;
  final VoidCallback? onReactionTap;

  bool get _hasReactions => reactions.any((r) => r.count > 0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: _hasReactions ? 10 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: isMine ? Alignment.bottomLeft : Alignment.bottomRight,
        children: [
          bubble,
          if (_hasReactions)
            Positioned(
              bottom: -8,
              left: isMine ? 6 : null,
              right: isMine ? null : 6,
              child: MessageReactionChip(
                reactions: reactions,
                isMine: isMine,
                onTap: onReactionTap,
              ),
            ),
        ],
      ),
    );
  }
}
