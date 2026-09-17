import 'package:flutter/material.dart';

abstract final class MomentDecorations {
  static const streak = 'Streak';
  static const partyTime = 'Party time';
  static const ootd = 'OOTD';
  static const missingYou = 'Missing you';

  static const all = [streak, partyTime, ootd, missingYou];

  /// Tags shown in the decorative section of the captions sheet.
  static const decorative = [partyTime, ootd, missingYou];

  static String emojiFor(String tag) => switch (tag) {
    streak => '🔥',
    partyTime => '🪩',
    ootd => '🕶️',
    missingYou => '🥰',
    _ => '✨',
  };

  static String displayLabel(String tag) => switch (tag) {
    partyTime => 'Party Time!',
    missingYou => 'Miss you',
    ootd => 'OOTD',
    streak => 'Streak',
    _ => tag,
  };

  static DecorationPillStyle pillStyle(String tag) => switch (tag) {
    partyTime => const DecorationPillStyle(
      gradient: LinearGradient(
        colors: [Color(0xFF5CE1E6), Color(0xFFB4F461)],
      ),
      textColor: Color(0xFF0A1A12),
    ),
    missingYou => const DecorationPillStyle(
      background: Color(0xFFE85D3A),
      textColor: Colors.white,
    ),
    ootd => const DecorationPillStyle(
      background: Colors.white,
      textColor: Color(0xFF1C1216),
    ),
    streak => const DecorationPillStyle(
      gradient: LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFFB020)],
      ),
      textColor: Color(0xFF3D2800),
    ),
    _ => const DecorationPillStyle(
      background: Color(0xFF2A2A2E),
      textColor: Colors.white,
    ),
  };
}

class DecorationPillStyle {
  const DecorationPillStyle({
    this.background,
    this.gradient,
    this.textColor = Colors.white,
  });

  final Color? background;
  final Gradient? gradient;
  final Color textColor;
}
