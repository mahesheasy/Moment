import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';

/// Maps [WidgetTypography] to Flutter [TextStyle]s for widget previews.
class WidgetTypographyStyles {
  const WidgetTypographyStyles._();

  static TextStyle label(
    WidgetTypography typography, {
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w600,
    double? letterSpacing,
    double? height,
  }) {
    final base = TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );

    return switch (typography) {
      WidgetTypography.defaultStyle => base.copyWith(
        fontFamily: AppTypography.fontFamily,
        fontWeight: weight,
      ),
      WidgetTypography.serif => base.copyWith(
        fontFamily: 'serif',
        fontWeight: weight,
      ),
      WidgetTypography.rounded => base.copyWith(
        fontFamily: AppTypography.fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: (letterSpacing ?? 0) + 0.6,
      ),
      WidgetTypography.mono => base.copyWith(
        fontFamily: 'monospace',
        fontWeight: weight,
        letterSpacing: (letterSpacing ?? 0) + 0.4,
      ),
    };
  }

  static TextStyle caption(
    WidgetTypography typography, {
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w500,
  }) {
    return label(
      typography,
      size: size,
      color: color,
      weight: weight,
      letterSpacing: 0.15,
    );
  }

  /// Sample glyph for typography picker rows.
  static TextStyle sample(WidgetTypography typography, Color color) {
    return label(typography, size: 22, color: color, weight: FontWeight.w600);
  }
}
