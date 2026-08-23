import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';

class MomentChip extends StatelessWidget {
  const MomentChip({
    required this.label,
    super.key,
    this.selected = false,
    this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      avatar: leading,
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
      showCheckmark: false,
      selectedColor: AppColors.accentSoft,
      side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? AppColors.accent : AppColors.textSecondary,
      ),
    );
  }
}

class MomentBadge extends StatelessWidget {
  const MomentBadge({required this.label, super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.accentSoft;
    final fg = color != null ? AppColors.surface : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smAll),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
