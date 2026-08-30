import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/features/chat/presentation/models/moment_timeline_models.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';

class MomentReactionBar extends StatelessWidget {
  const MomentReactionBar({
    required this.reactions,
    this.onAddReaction,
    super.key,
  });

  final List<MomentReactionSummary> reactions;
  final VoidCallback? onAddReaction;

  @override
  Widget build(BuildContext context) {
    if (reactions.every((r) => r.count == 0)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 2),
      child: Row(
        children: [
          for (final reaction in reactions)
            if (reaction.count > 0) ...[
              _ReactionPill(
                emoji: reaction.emoji,
                count: reaction.count,
              ),
              const SizedBox(width: 6),
            ],
          _AddReactionButton(onTap: onAddReaction),
        ],
      ),
    );
  }
}

class _ReactionPill extends StatelessWidget {
  const _ReactionPill({required this.emoji, required this.count});

  final String emoji;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MomentSpaceTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MomentSpaceTheme.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MomentSpaceTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddReactionButton extends StatelessWidget {
  const _AddReactionButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MomentSpaceTheme.surfaceElevated,
            border: Border.all(color: MomentSpaceTheme.border(context)),
          ),
          child: Icon(
            Icons.add_reaction_outlined,
            size: 14,
            color: MomentSpaceTheme.textTertiary(context),
          ),
        ),
      ),
    );
  }
}
