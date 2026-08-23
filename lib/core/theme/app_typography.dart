import 'package:flutter/material.dart';

/// Typography scale — Poppins, compact professional hierarchy.
///
/// Core sizes: 10 caption · 12 body · 14 title
class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Poppins';

  // Fixed palette literals for static [TextTheme] construction.
  static const Color _lightTextPrimary = Color(0xFF1C1216);
  static const Color _lightTextSecondary = Color(0xFF5E4A50);
  static const Color _lightTextTertiary = Color(0xFF9A848C);
  static const Color _darkTextPrimary = Color(0xFFF8F1F4);
  static const Color _darkTextSecondary = Color(0xFFC4B3BB);
  static const Color _darkTextTertiary = Color(0xFF8A7882);

  static TextTheme lightTextTheme = TextTheme(
    displayLarge: _display(22, _lightTextPrimary),
    displayMedium: _display(20, _lightTextPrimary),
    displaySmall: _display(18, _lightTextPrimary),
    headlineLarge: _headline(17, _lightTextPrimary, FontWeight.w600),
    headlineMedium: _headline(15, _lightTextPrimary, FontWeight.w600),
    headlineSmall: _headline(14, _lightTextPrimary, FontWeight.w600),
    titleLarge: _title(14, _lightTextPrimary, FontWeight.w600),
    titleMedium: _title(13, _lightTextPrimary, FontWeight.w600),
    titleSmall: _title(12, _lightTextPrimary, FontWeight.w600),
    bodyLarge: _body(13, _lightTextPrimary),
    bodyMedium: _body(12, _lightTextSecondary),
    bodySmall: _body(10, _lightTextTertiary),
    labelLarge: _label(12, _lightTextPrimary, FontWeight.w500),
    labelMedium: _label(11, _lightTextSecondary, FontWeight.w500),
    labelSmall: _label(10, _lightTextTertiary, FontWeight.w500),
  );

  static TextTheme darkTextTheme = TextTheme(
    displayLarge: _display(22, _darkTextPrimary),
    displayMedium: _display(20, _darkTextPrimary),
    displaySmall: _display(18, _darkTextPrimary),
    headlineLarge: _headline(17, _darkTextPrimary, FontWeight.w600),
    headlineMedium: _headline(15, _darkTextPrimary, FontWeight.w600),
    headlineSmall: _headline(14, _darkTextPrimary, FontWeight.w600),
    titleLarge: _title(14, _darkTextPrimary, FontWeight.w600),
    titleMedium: _title(13, _darkTextPrimary, FontWeight.w600),
    titleSmall: _title(12, _darkTextPrimary, FontWeight.w600),
    bodyLarge: _body(13, _darkTextPrimary),
    bodyMedium: _body(12, _darkTextSecondary),
    bodySmall: _body(10, _darkTextTertiary),
    labelLarge: _label(12, _darkTextPrimary, FontWeight.w500),
    labelMedium: _label(11, _darkTextSecondary, FontWeight.w500),
    labelSmall: _label(10, _darkTextTertiary, FontWeight.w500),
  );

  static TextStyle greeting(BuildContext context) {
    return Theme.of(context).textTheme.headlineLarge!.copyWith(
      letterSpacing: -0.25,
      height: 1.2,
    );
  }

  static TextStyle relationshipHeader(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
      letterSpacing: 0.05,
    );
  }

  static TextStyle metadata(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(letterSpacing: 0.15);
  }

  static TextStyle _display(double size, Color color) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.4,
    height: 1.15,
    color: color,
  );

  static TextStyle _headline(double size, Color color, FontWeight weight) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -0.2,
        height: 1.25,
        color: color,
      );

  static TextStyle _title(double size, Color color, FontWeight weight) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -0.1,
        height: 1.3,
        color: color,
      );

  static TextStyle _body(double size, Color color) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.05,
    height: 1.45,
    color: color,
  );

  static TextStyle _label(double size, Color color, FontWeight weight) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0.25,
        height: 1.2,
        color: color,
      );
}
