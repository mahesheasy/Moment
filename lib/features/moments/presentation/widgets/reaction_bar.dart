import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';

class ReactionBar extends StatelessWidget {
  const ReactionBar({
    required this.summary,
    required this.onReact,
    required this.onPing,
    super.key,
  });

  final MomentReactionSummary? summary;
  final VoidCallback onReact;
  final VoidCallback? onPing;

  @override
  Widget build(BuildContext context) {
    final myReaction = summary?.myReaction;
    final total = summary?.total ?? 0;
    final reacted = myReaction != null;

    return Row(
      children: [
        _ReactionPill(
          icon: reacted ? AppIcons.heartFilled : AppIcons.heart,
          emoji: myReaction?.emoji,
          label: total > 0 ? '$total' : 'React',
          selected: reacted,
          onTap: onReact,
        ),
        if (onPing != null) ...[
          const SizedBox(width: AppSpacing.md),
          _ReactionPill(
            icon: AppIcons.wave,
            label: 'Ping',
            selected: false,
            onTap: onPing!,
          ),
        ],
      ],
    );
  }
}

class _ReactionPill extends StatelessWidget {
  const _ReactionPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
  });

  final IconData icon;
  final String? emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (isDark ? AppColors.violet : AppColors.accent)
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary);
    final background = selected
        ? (isDark ? AppColors.accentSoftDark : AppColors.accentSoft)
        : (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevated);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null)
                Text(emoji!, style: const TextStyle(fontSize: 16))
              else
                Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
