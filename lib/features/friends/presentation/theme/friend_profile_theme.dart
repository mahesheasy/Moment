import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';

/// Visual tokens for the premium friend relationship profile screen.
abstract final class FriendProfileTheme {
  static const backgroundTop = Color(0xFF0A0812);
  static const backgroundBottom = Color(0xFF06060A);
  static const surface = Color(0xFF14121C);
  static const surfaceGlass = Color(0xCC14121C);
  static const border = Color(0x1AFFFFFF);
  static const borderAccent = Color(0x338B5CF6);
  static const glowPurple = Color(0x406366F1);
  static const onlineGreen = Color(0xFF34C759);
  static const destructive = Color(0xFFFF6B8A);
  static const statPurple = Color(0xFFC4A1FF);
  static const statBlue = Color(0xFF5AC8FA);
  static const statPink = Color(0xFFFF6B8A);
  static const statCyan = Color(0xFF5EEAD4);

  static const avatarOuter = 120.0;
  static const avatarInner = 108.0;
  static const cardRadius = AppRadius.xl;
  static const buttonRadius = 28.0;
  static const buttonHeight = 54.0;
  static const secondaryButtonHeight = 52.0;

  static const pagePadding = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

  static LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [backgroundTop, backgroundBottom],
      );

  static LinearGradient get messageButtonGradient => const LinearGradient(
        colors: [Color(0xFFFF5B7A), Color(0xFFFF8A5C)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static LinearGradient get avatarRingGradient => const LinearGradient(
        colors: [
          Color(0xFFFF5B7A),
          Color(0xFFC4A1FF),
          Color(0xFF5AC8FA),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static BoxDecoration surfaceCard({Color? borderColor}) {
    return BoxDecoration(
      color: surface.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: borderColor ?? border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
