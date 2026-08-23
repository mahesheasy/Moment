import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';

/// Very soft elevation — premium restraint, not heavy Material shadows.
class AppShadows {
  const AppShadows._();

  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.08),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get cameraCapsule => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.18),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get cameraGlow => [
    BoxShadow(
      color: AppColors.violet.withValues(alpha: 0.42),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];
}
