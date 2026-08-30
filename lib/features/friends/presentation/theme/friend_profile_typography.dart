import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';

/// Balanced type scale for the friend profile screen.
abstract final class FriendProfileTextStyles {
  static const displayName = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.35,
    color: Colors.white,
    height: 1.15,
    decoration: TextDecoration.none,
  );

  static final username = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.white.withValues(alpha: 0.52),
    height: 1.2,
    decoration: TextDecoration.none,
  );

  static final bio = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Colors.white.withValues(alpha: 0.62),
    decoration: TextDecoration.none,
  );

  static const statValue = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: Colors.white,
    height: 1.1,
    decoration: TextDecoration.none,
  );

  static final statLabel = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Colors.white.withValues(alpha: 0.48),
    height: 1.2,
    decoration: TextDecoration.none,
  );

  static const sectionTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    color: Colors.white,
    height: 1.25,
    decoration: TextDecoration.none,
  );

  static final sectionBody = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: Colors.white.withValues(alpha: 0.5),
    decoration: TextDecoration.none,
  );

  static final aboutLabel = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white.withValues(alpha: 0.5),
    height: 1.3,
    decoration: TextDecoration.none,
  );

  static const aboutValue = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.3,
    decoration: TextDecoration.none,
  );

  static const onlineStatus = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    decoration: TextDecoration.none,
  );
}
