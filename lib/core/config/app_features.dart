/// Product feature flags — flip before release.
class AppFeatures {
  const AppFeatures._();

  /// When `true`, all widget themes and customization work without Moment+.
  /// Set to `false` before release to restore the paywall.
  static const bool momentPlusWidgetsUnlocked = true;

  /// When `true`, Circles are available without Moment+ (development only).
  static const bool momentPlusCirclesUnlocked = true;

  /// When `true`, custom circle photos work without Moment+ (development only).
  static const bool momentPlusCirclePhotosUnlocked = true;
}
