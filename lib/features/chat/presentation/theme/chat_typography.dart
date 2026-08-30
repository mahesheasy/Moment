import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';

/// Shared chat typography tokens for a clean, professional messaging UI.
abstract final class ChatTypography {
  static const _family = AppTypography.fontFamily;

  static TextStyle inboxTitle(BuildContext context, {Color? color}) =>
      TextStyle(
        fontFamily: _family,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.1,
        color: color ?? Colors.white,
      );

  static TextStyle inboxSubtitle({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: color,
      );

  static TextStyle inboxName({required bool unread, Color? color}) =>
      TextStyle(
        fontFamily: _family,
        fontSize: 15,
        fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: -0.2,
        color: color ?? Colors.white,
      );

  static TextStyle inboxPreview({required bool unread, Color? color}) =>
      TextStyle(
        fontFamily: _family,
        fontSize: 13,
        fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
        height: 1.35,
        color: color,
      );

  static TextStyle inboxTime({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle bubbleBody({required bool isMine, Color? color}) =>
      TextStyle(
        fontFamily: _family,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: -0.1,
        color: color ?? (isMine ? Colors.white : null),
      );

  static TextStyle bubbleMeta({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle quoteName({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: color,
      );

  static TextStyle quoteBody({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 1.2,
        color: color,
      );

  static TextStyle sheetAction({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// Bottom sheet rows on the chat inbox (long-press menu).
  static TextStyle inboxSheetAction({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
        color: color,
      );

  static TextStyle headerName({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle headerStatus({Color? color}) => TextStyle(
        fontFamily: _family,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );
}
