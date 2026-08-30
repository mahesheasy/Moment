import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_shadows.dart';
import 'package:moment/core/theme/moment_theme.dart';

/// Visual tokens for the private Moments space (relationship timeline).
abstract final class MomentSpaceTheme {
  static const background = Color(0xFF0B0D14);
  static const composerBarBackground = Color(0xFF0B0B0F);
  static const composerPillBackground = Color(0xFF1A1A2E);
  static const surface = Color(0xFF10121C);
  static const surfaceElevated = Color(0xFF161A24);
  static const timelineLine = Color(0xFF252A36);
  static const onlineGreen = Color(0xFF34C759);
  static const readBlue = Color(0xFF5AC8FA);

  // Compact layout scale
  static const cardRadius = 14.0;
  static const pillRadius = 18.0;
  static const railWidth = 28.0;
  static const nodeSize = 8.0;
  static const railLineHeight = 20.0;
  static const avatarTimeline = 26.0;
  static const avatarHeader = 40.0;
  static const iconButtonSize = 30.0;
  static const composerHeight = 36.0;
  static const sendButtonSize = 36.0;

  static Color border(BuildContext context) =>
      context.mc.border.withValues(alpha: 0.55);

  static Color textPrimary(BuildContext context) => context.mc.textPrimary;

  static Color textSecondary(BuildContext context) => context.mc.textSecondary;

  static Color textTertiary(BuildContext context) => context.mc.textTertiary;

  static LinearGradient accentGradient(BuildContext context) =>
      context.mc.bloomGradient;

  static List<BoxShadow> nodeGlow(BuildContext context) => [
        BoxShadow(
          color: context.mc.accent.withValues(alpha: 0.45),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> cardShadow = AppShadows.subtle;

  static BoxDecoration cardDecoration(
    BuildContext context, {
    BorderRadius? radius,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      gradient: gradient,
      color: gradient == null ? surface : null,
      borderRadius: radius ?? BorderRadius.circular(cardRadius),
      border: Border.all(color: border(context)),
      boxShadow: cardShadow,
    );
  }

  static BoxDecoration pillDecoration(
    BuildContext context, {
    bool active = false,
  }) {
    if (active) {
      return BoxDecoration(
        gradient: accentGradient(context),
        borderRadius: BorderRadius.circular(pillRadius),
        boxShadow: [
          BoxShadow(
            color: context.mc.accent.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
    return BoxDecoration(
      color: surfaceElevated.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(pillRadius),
      border: Border.all(color: border(context)),
    );
  }

  static BoxDecoration iconButtonDecoration(BuildContext context) {
    return BoxDecoration(
      color: surfaceElevated.withValues(alpha: 0.9),
      shape: BoxShape.circle,
      border: Border.all(color: border(context)),
    );
  }

  static BorderRadius messageRadiusMine = const BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(20),
    bottomRight: Radius.circular(6),
  );

  static BorderRadius messageRadiusTheirs = const BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(6),
    bottomRight: Radius.circular(20),
  );

  static BoxDecoration mineBubbleDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: accentGradient(context),
      borderRadius: messageRadiusMine,
      boxShadow: [
        BoxShadow(
          color: context.mc.accent.withValues(alpha: 0.22),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration theirsBubbleDecoration(BuildContext context) {
    return BoxDecoration(
      color: const Color(0xFF181C26),
      borderRadius: messageRadiusTheirs,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }

  static BoxDecoration composerShellDecoration(
    BuildContext context, {
    required bool focused,
  }) {
    return BoxDecoration(
      color: const Color(0xFF13161F),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: focused
            ? context.mc.accent.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.08),
        width: focused ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
        if (focused)
          BoxShadow(
            color: context.mc.accent.withValues(alpha: 0.14),
            blurRadius: 22,
          ),
      ],
    );
  }
}
