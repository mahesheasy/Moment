import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_colors.dart';

/// Velvet Bloom — warm nocturnal photography palette.
///
/// Base constants are compile-time defaults. At runtime, [bind] syncs the
/// `*Dark` semantic tokens and accent colors from [MomentColors] so existing
/// screens pick up light/dark mode and the user accent without refactors.
class AppColors {
  const AppColors._();

  static MomentColors? _active;

  /// Called from [MaterialApp.builder] whenever the theme updates.
  static void bind(MomentColors colors) => _active = colors;

  static MomentColors get active =>
      _active ?? MomentColors.resolve(brightness: Brightness.dark);

  // Light — blush paper (static reference palette)
  static const Color background = Color(0xFFF6F0F2);
  static const Color surface = Color(0xFFFFFBFC);
  static const Color surfaceElevated = Color(0xFFF8F0F3);
  static const Color textPrimary = Color(0xFF1C1216);
  static const Color textSecondary = Color(0xFF5E4A50);
  static const Color textTertiary = Color(0xFF9A848C);
  static const Color border = Color(0xFFE8D8DE);
  static const Color accent = Color(0xFFC43D5C);
  static const Color accentSoft = Color(0xFFF8E4EA);
  static const Color ink = Color(0xFF1C1216);
  static const Color cream = Color(0xFFF8F0F3);
  static const Color success = Color(0xFF2F7A4E);
  static const Color warning = Color(0xFFC46B1A);
  static const Color error = Color(0xFFC42B3A);
  static const Color overlay = Color(0x661C1216);
  static const Color photoPlaceholder = Color(0xFFEDE0E4);

  static const Color photoPink = Color(0xFFFF5C7A);
  static const Color sendCoral = Color(0xFFFF8A5C);
  static const Color nextPurple = Color(0xFFC4A1FF);
  static const Color champagne = Color(0xFFE8C39E);

  static const Color _defaultViolet = Color(0xFFFF6B8A);
  static const Color _defaultVioletSoft = Color(0x33FF6B8A);

  /// Primary accent — follows user selection when bound.
  static Color get violet => active.accent;

  /// Soft accent wash.
  static Color get violetSoft => active.accentSoft;

  /// CTA / premium gradient from the active accent.
  static LinearGradient get bloomGradient => active.bloomGradient;

  // Semantic tokens — map to the active theme (light or dark).
  static Color get backgroundDark => active.background;
  static Color get surfaceDark => active.surface;
  static Color get surfaceElevatedDark => active.surfaceElevated;
  static Color get textPrimaryDark => active.textPrimary;
  static Color get textSecondaryDark => active.textSecondary;
  static Color get textTertiaryDark => active.textTertiary;
  static Color get borderDark => active.border;
  static Color get accentDark => active.accent;
  static Color get accentSoftDark => active.accentSoft;
  static Color get errorDark => active.error;
  static Color get photoPlaceholderDark => active.photoPlaceholder;
}
