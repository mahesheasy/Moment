import 'package:flutter/animation.dart';

/// Motion tokens — subtle, meaningful animation only.
class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration emphasis = Duration(milliseconds: 350);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;
}

/// Alias used in spec as AppAnimations.
typedef AppAnimations = AppDurations;
