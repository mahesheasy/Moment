import 'package:flutter/material.dart';

/// Minimal chat palette — flat, readable, no glow or gradients.
abstract final class ChatTheme {
  static const threadBackground = Color(0xFF0D0D0F);
  static const headerBackground = Color(0xFF0D0D0F);
  static const receivedBubble = Color(0xFF262628);
  static const sentBubble = Color(0xFF5E52D4);
  static const inputBackground = Color(0xFF1C1C1E);
  static const inputBorder = Color(0xFF2C2C2E);
  static const divider = Color(0xFF2C2C2E);
  static const tertiaryText = Color(0xFF8E8E93);
  static const accent = Color(0xFF5E52D4);
  static const readReceipt = Color(0xFF8E8E93);
  static const onlineGreen = Color(0xFF34C759);

  /// Legacy alias used by inbox widgets.
  static const accentPink = accent;

  static Color threadBackdrop(bool isDark) {
    return isDark ? threadBackground : const Color(0xFFF2F2F7);
  }

  static Color receivedBubbleFor(bool isDark) {
    return isDark ? receivedBubble : const Color(0xFFE9E9EB);
  }

  static Color sentBubbleFor(bool isDark) {
    return isDark ? sentBubble : const Color(0xFF5E52D4);
  }

  static Color primaryText(bool isDark) {
    return isDark ? Colors.white : const Color(0xFF1C1C1E);
  }

  static Color secondaryText(bool isDark) {
    return isDark ? tertiaryText : const Color(0xFF8E8E93);
  }

  /// Legacy — inbox still references this name.
  static LinearGradient threadBackdropGradient(bool isDark) {
    final color = threadBackdrop(isDark);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color, color],
    );
  }

  /// Legacy — friend chips / stories.
  static const actionGradient = LinearGradient(
    colors: [accent, accent],
  );
}
