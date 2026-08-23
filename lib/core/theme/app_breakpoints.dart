import 'package:flutter/material.dart';

/// Responsive breakpoints for small phones, large phones, and tablets.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double tablet = 600;
  static const double largeTablet = 840;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  static bool isLargeTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= largeTablet;

  /// Max content width on tablet for photo-first layouts.
  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= largeTablet) return 520;
    if (width >= tablet) return 480;
    return width;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final horizontal = isTablet(context) ? AppBreakpoints._tabletPad : 20.0;
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  static const double _tabletPad = 32;
}
