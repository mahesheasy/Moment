import 'package:flutter/material.dart';
import 'package:moment/core/theme/accent_presets.dart';

/// Semantic colors that adapt to light/dark mode and the user accent.
@immutable
class MomentColors extends ThemeExtension<MomentColors> {
  const MomentColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.error,
    required this.photoPlaceholder,
    required this.bloomGradient,
    required this.cardGradient,
    required this.sendCoral,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final Color error;
  final Color photoPlaceholder;
  final LinearGradient bloomGradient;
  final LinearGradient cardGradient;
  final Color sendCoral;

  // Base palette literals — avoid [AppColors] to prevent bind cycles.
  static const _lightBackground = Color(0xFFF6F0F2);
  static const _lightSurface = Color(0xFFFFFBFC);
  static const _lightSurfaceElevated = Color(0xFFF8F0F3);
  static const _lightTextPrimary = Color(0xFF1C1216);
  static const _lightTextSecondary = Color(0xFF5E4A50);
  static const _lightTextTertiary = Color(0xFF9A848C);
  static const _lightBorder = Color(0xFFE8D8DE);
  static const _lightError = Color(0xFFC42B3A);
  static const _lightPhotoPlaceholder = Color(0xFFEDE0E4);

  static const _darkBackground = Color(0xFF0B090E);
  static const _darkSurface = Color(0xFF16121A);
  static const _darkSurfaceElevated = Color(0xFF211A24);
  static const _darkTextPrimary = Color(0xFFF8F1F4);
  static const _darkTextSecondary = Color(0xFFC4B3BB);
  static const _darkTextTertiary = Color(0xFF8A7882);
  static const _darkBorder = Color(0xFF2E2630);
  static const _darkError = Color(0xFFFF8A8A);
  static const _darkPhotoPlaceholder = Color(0xFF261E26);

  factory MomentColors.resolve({
    required Brightness brightness,
    Color accent = const Color(0xFFFF6B8A),
  }) {
    final isDark = brightness == Brightness.dark;
    final soft = accentSoftFor(accent, isDark: isDark);
    final warm = Color.lerp(accent, const Color(0xFFFF8A5C), 0.45)!;

    if (isDark) {
      return MomentColors(
        background: _darkBackground,
        surface: _darkSurface,
        surfaceElevated: _darkSurfaceElevated,
        textPrimary: _darkTextPrimary,
        textSecondary: _darkTextSecondary,
        textTertiary: _darkTextTertiary,
        border: _darkBorder,
        accent: accent,
        accentSoft: soft,
        error: _darkError,
        photoPlaceholder: _darkPhotoPlaceholder,
        bloomGradient: bloomGradientFor(accent),
        cardGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1524),
            Color(0xFF16121A),
            Color(0xFF120E16),
          ],
        ),
        sendCoral: warm,
      );
    }

    return MomentColors(
      background: _lightBackground,
      surface: _lightSurface,
      surfaceElevated: _lightSurfaceElevated,
      textPrimary: _lightTextPrimary,
      textSecondary: _lightTextSecondary,
      textTertiary: _lightTextTertiary,
      border: _lightBorder,
      accent: accent,
      accentSoft: soft,
      error: _lightError,
      photoPlaceholder: _lightPhotoPlaceholder,
      bloomGradient: bloomGradientFor(accent),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(_lightSurface, accent, 0.06)!,
          _lightSurface,
          Color.lerp(_lightSurfaceElevated, accent, 0.04)!,
        ],
      ),
      sendCoral: warm,
    );
  }

  @override
  MomentColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? accent,
    Color? accentSoft,
    Color? error,
    Color? photoPlaceholder,
    LinearGradient? bloomGradient,
    LinearGradient? cardGradient,
    Color? sendCoral,
  }) {
    return MomentColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      error: error ?? this.error,
      photoPlaceholder: photoPlaceholder ?? this.photoPlaceholder,
      bloomGradient: bloomGradient ?? this.bloomGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      sendCoral: sendCoral ?? this.sendCoral,
    );
  }

  @override
  MomentColors lerp(ThemeExtension<MomentColors>? other, double t) {
    if (other is! MomentColors) return this;
    return MomentColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      photoPlaceholder: Color.lerp(photoPlaceholder, other.photoPlaceholder, t)!,
      bloomGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(bloomGradient.colors.first, other.bloomGradient.colors.first, t)!,
          Color.lerp(bloomGradient.colors.last, other.bloomGradient.colors.last, t)!,
        ],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(cardGradient.colors[0], other.cardGradient.colors[0], t)!,
          Color.lerp(cardGradient.colors[1], other.cardGradient.colors[1], t)!,
          Color.lerp(cardGradient.colors[2], other.cardGradient.colors[2], t)!,
        ],
      ),
      sendCoral: Color.lerp(sendCoral, other.sendCoral, t)!,
    );
  }
}
