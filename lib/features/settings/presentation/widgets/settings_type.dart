import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';

/// Settings & Privacy type scale — 10, 12, and 14 only.
class SettingsType {
  const SettingsType._();

  static TextStyle title(Color color) => TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.28,
    color: color,
  );

  static TextStyle body(Color color) => TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.08,
    height: 1.4,
    color: color,
  );

  static TextStyle caption(Color color) => TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.3,
    color: color,
  );
}
