import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';

class CameraGradientButton extends StatelessWidget {
  const CameraGradientButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: AppColors.bloomGradient,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CameraSelectionCheck extends StatelessWidget {
  const CameraSelectionCheck({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.violet : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.violet : AppColors.borderDark,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(AppIcons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

Color circleAccentColor(CircleType type) {
  return switch (type) {
    CircleType.us => AppColors.violet,
    CircleType.squad => AppColors.nextPurple,
    CircleType.family => const Color(0xFF5DDBA0),
    CircleType.college => const Color(0xFF7EB6FF),
    CircleType.custom => AppColors.champagne,
  };
}
