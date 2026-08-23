import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_colors.dart';

extension MomentThemeX on BuildContext {
  /// Theme-aware semantic colors (light/dark + accent).
  MomentColors get mc =>
      Theme.of(this).extension<MomentColors>() ??
      MomentColors.resolve(brightness: Theme.of(this).brightness);

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
