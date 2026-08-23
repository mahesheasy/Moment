import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_shadows.dart';
import 'package:moment/core/theme/app_spacing.dart';

class MomentCard extends StatelessWidget {
  const MomentCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding,
    this.color,
    this.elevated = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = color ?? Theme.of(context).colorScheme.surface;

    return Material(
      color: background,
      borderRadius: AppRadius.xlAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.xlAll,
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.xlAll,
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark.withValues(alpha: 0.7)
                  : AppColors.border.withValues(alpha: 0.9),
            ),
            boxShadow: elevated && !isDark ? AppShadows.subtle : null,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}
