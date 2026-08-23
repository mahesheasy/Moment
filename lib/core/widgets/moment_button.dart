import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_component_sizes.dart';
import 'package:moment/core/theme/app_durations.dart';
import 'package:moment/core/theme/app_radius.dart';

enum MomentButtonVariant { primary, secondary, ghost }

enum MomentButtonSize { medium, large }

class MomentButton extends StatelessWidget {
  const MomentButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = MomentButtonVariant.primary,
    this.size = MomentButtonSize.medium,
    this.expanded = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final MomentButtonVariant variant;
  final MomentButtonSize size;
  final bool expanded;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final height = size == MomentButtonSize.large
        ? AppComponentSizes.buttonHeightLg
        : AppComponentSizes.buttonHeightMd;
    final child = isLoading
        ? SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == MomentButtonVariant.primary
                  ? Theme.of(context).colorScheme.onPrimary
                  : AppColors.accent,
            ),
          )
        : Text(label);

    return AnimatedOpacity(
      duration: AppDurations.fast,
      opacity: onPressed == null && !isLoading ? 0.5 : 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded = constraints.maxWidth.isFinite;
          final minWidth = expanded && bounded ? constraints.maxWidth : 0.0;

          return switch (variant) {
            MomentButtonVariant.primary => ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(minWidth, height),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: child,
            ),
            MomentButtonVariant.secondary => OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: Size(minWidth, height),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: child,
            ),
            MomentButtonVariant.ghost => TextButton(
              onPressed: isLoading ? null : onPressed,
              style: TextButton.styleFrom(
                minimumSize: Size(minWidth, height),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: child,
            ),
          };
        },
      ),
    );
  }
}

class MomentTextButton extends StatelessWidget {
  const MomentTextButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}

class MomentIconButton extends StatelessWidget {
  const MomentIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.semanticLabel,
    this.size = AppComponentSizes.iconButton,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.lgAll,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: AppComponentSizes.iconMd),
          ),
        ),
      ),
    );
  }
}
