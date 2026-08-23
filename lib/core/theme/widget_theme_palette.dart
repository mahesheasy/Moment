import 'package:flutter/material.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';

/// Visual palette for each home-widget relationship theme.
class WidgetThemePalette {
  const WidgetThemePalette({
    required this.label,
    required this.emoji,
    required this.defaultAccent,
    required this.gradient,
    required this.overlayTop,
    required this.overlayBottom,
    required this.actionColor,
  });

  final String label;
  final String emoji;
  final String defaultAccent;
  final List<Color> gradient;
  final Color overlayTop;
  final Color overlayBottom;
  final Color actionColor;

  static WidgetThemePalette forTheme(WidgetTheme theme) {
    return _palettes[theme] ?? _palettes[WidgetTheme.minimal]!;
  }

  static const _palettes = {
    WidgetTheme.love: WidgetThemePalette(
      label: 'Love',
      emoji: '💕',
      defaultAccent: '#FF6B8A',
      gradient: [Color(0xFF4A2030), Color(0xFF2A121C), Color(0xFF12080E)],
      overlayTop: Color(0xAA2A121C),
      overlayBottom: Color(0xCC1A0A12),
      actionColor: Color(0xFFFF8FA8),
    ),
    WidgetTheme.family: WidgetThemePalette(
      label: 'Family',
      emoji: '👨‍👩‍👧',
      defaultAccent: '#7EB6FF',
      gradient: [Color(0xFF2A3A52), Color(0xFF1A2438), Color(0xFF0D121C)],
      overlayTop: Color(0xAA1A2438),
      overlayBottom: Color(0xCC121A28),
      actionColor: Color(0xFF9ECBFF),
    ),
    WidgetTheme.friends: WidgetThemePalette(
      label: 'Friends',
      emoji: '👥',
      defaultAccent: '#5DDBA0',
      gradient: [Color(0xFF1F3D34), Color(0xFF142820), Color(0xFF0A1410)],
      overlayTop: Color(0xAA142820),
      overlayBottom: Color(0xCC0F1E18),
      actionColor: Color(0xFF7EEBB8),
    ),
    WidgetTheme.bestie: WidgetThemePalette(
      label: 'Bestie',
      emoji: '✨',
      defaultAccent: '#FFB86C',
      gradient: [Color(0xFF3D3020), Color(0xFF2A2014), Color(0xFF14100A)],
      overlayTop: Color(0xAA2A2014),
      overlayBottom: Color(0xCC1E160E),
      actionColor: Color(0xFFFFCA8A),
    ),
    WidgetTheme.minimal: WidgetThemePalette(
      label: 'Clean',
      emoji: '◻️',
      defaultAccent: '#C4A484',
      gradient: [Color(0xFF2A2428), Color(0xFF1A1618), Color(0xFF0B090E)],
      overlayTop: Color(0xAA000000),
      overlayBottom: Color(0xCC000000),
      actionColor: Color(0xFFE8C39E),
    ),
    WidgetTheme.glass: WidgetThemePalette(
      label: 'Glass',
      emoji: '🪟',
      defaultAccent: '#A8C8FF',
      gradient: [Color(0xFF2A2A32), Color(0xFF1A1A22), Color(0xFF101018)],
      overlayTop: Color(0x661A1A22),
      overlayBottom: Color(0x99000000),
      actionColor: Color(0xFFB8D4FF),
    ),
    WidgetTheme.film: WidgetThemePalette(
      label: 'Film',
      emoji: '🎞️',
      defaultAccent: '#E8C39E',
      gradient: [Color(0xFF2A2218), Color(0xFF1A140E), Color(0xFF0A0806)],
      overlayTop: Color(0xAA1A140E),
      overlayBottom: Color(0xCC0A0806),
      actionColor: Color(0xFFE8C39E),
    ),
    WidgetTheme.polaroid: WidgetThemePalette(
      label: 'Polaroid',
      emoji: '📷',
      defaultAccent: '#F5F0E8',
      gradient: [Color(0xFF3A3632), Color(0xFF2A2622), Color(0xFF1A1614)],
      overlayTop: Color(0xAA2A2622),
      overlayBottom: Color(0xCC1A1614),
      actionColor: Color(0xFFF5F0E8),
    ),
    WidgetTheme.midnight: WidgetThemePalette(
      label: 'Midnight',
      emoji: '🌙',
      defaultAccent: '#9B8CFF',
      gradient: [Color(0xFF1A1830), Color(0xFF12101E), Color(0xFF08060E)],
      overlayTop: Color(0xAA12101E),
      overlayBottom: Color(0xCC08060E),
      actionColor: Color(0xFFB0A4FF),
    ),
    WidgetTheme.sunset: WidgetThemePalette(
      label: 'Sunset',
      emoji: '🌅',
      defaultAccent: '#FF9A6C',
      gradient: [Color(0xFF3D2818), Color(0xFF2A1A10), Color(0xFF140E08)],
      overlayTop: Color(0xAA2A1A10),
      overlayBottom: Color(0xCC140E08),
      actionColor: Color(0xFFFFB088),
    ),
    WidgetTheme.retro: WidgetThemePalette(
      label: 'Retro',
      emoji: '📼',
      defaultAccent: '#FF6B6B',
      gradient: [Color(0xFF3A2020), Color(0xFF281414), Color(0xFF140A0A)],
      overlayTop: Color(0xAA281414),
      overlayBottom: Color(0xCC140A0A),
      actionColor: Color(0xFFFF8888),
    ),
    WidgetTheme.memory: WidgetThemePalette(
      label: 'Memory',
      emoji: '🕯️',
      defaultAccent: '#D4A574',
      gradient: [Color(0xFF2A2218), Color(0xFF1A140E), Color(0xFF0A0806)],
      overlayTop: Color(0xAA1A140E),
      overlayBottom: Color(0xCC0A0806),
      actionColor: Color(0xFFE8C39E),
    ),
  };
}
