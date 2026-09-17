import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';

/// Chat palette derived from the app [MomentColors] theme extension.
abstract final class ChatTheme {
  static const onlineGreen = Color(0xFF34C759);
  static const readReceipt = Color(0xFF8E8E93);

  static Color threadBackground(BuildContext context) => context.mc.background;

  static Color headerBackground(BuildContext context) => context.mc.background;

  static Color receivedBubble(BuildContext context) =>
      context.mc.surfaceElevated;

  static Color sentBubble(BuildContext context) => context.mc.accent;

  static Color inputBackground(BuildContext context) => context.mc.surface;

  static Color inputBorder(BuildContext context) => context.mc.border;

  static Color divider(BuildContext context) => context.mc.border;

  static Color tertiaryText(BuildContext context) => context.mc.textTertiary;

  static Color accent(BuildContext context) => context.mc.accent;

  static Color primaryText(BuildContext context) => context.mc.textPrimary;

  static Color secondaryText(BuildContext context) => context.mc.textSecondary;

  static Color accentPink(BuildContext context) => context.mc.accent;

  static LinearGradient actionGradient(BuildContext context) =>
      context.mc.bloomGradient;

  static Color threadBackdrop(BuildContext context) => context.mc.background;

  static Color receivedBubbleFor(BuildContext context, bool isDark) =>
      receivedBubble(context);

  static Color sentBubbleFor(BuildContext context, bool isDark) =>
      sentBubble(context);

  static Color primaryTextFor(BuildContext context, bool isDark) =>
      primaryText(context);

  static Color secondaryTextFor(BuildContext context, bool isDark) =>
      secondaryText(context);

  static LinearGradient threadBackdropGradient(BuildContext context) {
    final color = threadBackdrop(context);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color, color],
    );
  }
}
