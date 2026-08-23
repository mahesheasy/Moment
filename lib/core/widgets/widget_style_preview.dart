import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/widget_theme_palette.dart';
import 'package:moment/core/theme/widget_typography_styles.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';
/// Home-screen widget preview — Full, Blur, Private, Memory.
class WidgetStylePreview extends StatelessWidget {
  const WidgetStylePreview({
    required this.preferences,
    this.headerTitle = 'Jay',
    this.relativeTime = '7m ago',
    this.previewSenderId,
    this.forcePrivacyMode,
    this.compact = false,
    this.showLabel = false,
    this.previewSize = 200,
    this.borderless = false,
    this.thumbnail = false,
    this.studioPreview = false,
    this.backgroundTint = 0.35,
    this.cornerRadius = 20,
    this.momentSourceLabel = 'Latest moment',
    super.key,
  });

  final WidgetPreferences preferences;
  final String headerTitle;
  final String relativeTime;
  final String? previewSenderId;
  /// When set, preview always shows this privacy mode (privacy settings screen).
  final WidgetPrivacyMode? forcePrivacyMode;
  final bool compact;
  final bool showLabel;
  final double previewSize;
  /// Skips the outer black bezel — used on the widget settings screen.
  final bool borderless;
  /// Tiny theme swatch — scales a full preview down, clipped to avoid overflow.
  final bool thumbnail;
  /// Home Widget studio layout — matches the customization screen mockup.
  final bool studioPreview;
  final double backgroundTint;
  final double cornerRadius;
  final String momentSourceLabel;

  WidgetPreferences get _resolved {
    if (forcePrivacyMode != null) {
      return preferences.copyWith(privacyMode: forcePrivacyMode);
    }
    if (previewSenderId == null) return preferences;
    return preferences.withPrivacyForPreview(senderId: previewSenderId);
  }

  Color get _accent => _parseAccent(preferences.accentColor);

  WidgetThemePalette get _palette => WidgetThemePalette.forTheme(preferences.theme);

  @override
  Widget build(BuildContext context) {
    if (thumbnail) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: previewSize,
          height: previewSize,
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: 220,
              height: 220,
              child: WidgetStylePreview(
                preferences: preferences,
                headerTitle: headerTitle,
                relativeTime: relativeTime,
                previewSenderId: previewSenderId,
                forcePrivacyMode: forcePrivacyMode,
                borderless: true,
                previewSize: 220,
              ),
            ),
          ),
        ),
      );
    }

    final size = compact ? 44.0 : previewSize;
    final radius = compact ? 14.0 : (borderless || studioPreview ? cornerRadius : 28.0);

    final face = compact
        ? _QuietMark(preferences: _resolved)
        : _MomentWidgetFace(
            preferences: _resolved,
            sender: headerTitle,
            relativeTime: relativeTime,
            accent: _accent,
            palette: _palette,
            studioPreview: studioPreview,
            backgroundTint: backgroundTint,
            momentSourceLabel: momentSourceLabel,
          );

    final Widget tile;
    if (compact) {
      const frame = 3.0;
      tile = SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(frame),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - frame),
              child: face,
            ),
          ),
        ),
      );
    } else if (borderless) {
      tile = SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: face,
        ),
      );
    } else {
      const frame = 12.0;
      tile = SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(frame),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - frame),
              child: face,
            ),
          ),
        ),
      );
    }

    if (compact || !showLabel) return tile;

    return Column(
      children: [
        Text(
          'PREVIEW',
          style: TextStyle(
            color: AppColors.textTertiaryDark,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 10),
        tile,
      ],
    );
  }

  static Color _parseAccent(String hex) {
    final normalized = hex.replaceFirst('#', '');
    final value = int.tryParse('FF$normalized', radix: 16);
    return Color(value ?? 0xFFFF6B8A);
  }
}

class WidgetThemeSwatch extends StatelessWidget {
  const WidgetThemeSwatch({
    required this.theme,
    required this.selected,
    required this.accentColor,
    this.typography = WidgetTypography.defaultStyle,
    this.onTap,
    super.key,
  });

  final WidgetTheme theme;
  final bool selected;
  final String accentColor;
  final WidgetTypography typography;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = WidgetThemePalette.forTheme(theme);
    final swatchAccent = theme.defaultAccent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? palette.actionColor : AppColors.borderDark,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Column(
          children: [
            WidgetStylePreview(
              preferences: WidgetPreferences(
                theme: theme,
                accentColor: swatchAccent,
                typography: typography,
                widgetMode: WidgetMode.latest,
              ),
              compact: true,
            ),
            SizedBox(height: 6),
            Text(
              '${palette.emoji} ${theme.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? AppColors.textPrimaryDark
                    : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietMark extends StatelessWidget {
  const _QuietMark({required this.preferences});

  final WidgetPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final palette = WidgetThemePalette.forTheme(preferences.theme);
    return switch (preferences.privacyMode) {
      WidgetPrivacyMode.private => ColoredBox(
        color: palette.gradient.last,
        child: Center(
          child: Text(palette.emoji, style: const TextStyle(fontSize: 14)),
        ),
      ),
      WidgetPrivacyMode.blur => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: _PhotoBed(theme: preferences.theme),
      ),
      _ when preferences.theme == WidgetTheme.memory => ColoredBox(
        color: Color(0xFF0B090E),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.all(6),
            child: ColoredBox(
              color: Color(0xFFFF8A5C),
              child: SizedBox(height: 12, width: double.infinity),
            ),
          ),
        ),
      ),
      _ => _PhotoBed(theme: preferences.theme),
    };
  }
}

class _MomentWidgetFace extends StatelessWidget {
  const _MomentWidgetFace({
    required this.preferences,
    required this.sender,
    required this.relativeTime,
    required this.accent,
    required this.palette,
    this.studioPreview = false,
    this.backgroundTint = 0.35,
    this.momentSourceLabel = 'Latest moment',
  });

  final WidgetPreferences preferences;
  final String sender;
  final String relativeTime;
  final Color accent;
  final WidgetThemePalette palette;
  final bool studioPreview;
  final double backgroundTint;
  final String momentSourceLabel;

  @override
  Widget build(BuildContext context) {
    final typography = preferences.typography;
    if (preferences.paused) {
      return _PrivateFace(
        title: 'Widget paused',
        from: sender,
        action: 'Tap to resume',
        typography: typography,
      );
    }
    if (preferences.theme == WidgetTheme.memory) {
      return _MemoryFace(sender: sender, typography: typography);
    }
    if (preferences.privacyMode == WidgetPrivacyMode.private) {
      return _PrivateFace(
        title: 'New Moment',
        from: 'From $sender',
        action: 'Tap to reveal',
        typography: typography,
      );
    }
    if (preferences.privacyMode == WidgetPrivacyMode.blur) {
      return _BlurFace(
        sender: sender,
        relativeTime: relativeTime,
        showSender: preferences.showSender,
        showTimestamp: preferences.showTimestamp,
        accent: accent,
        theme: preferences.theme,
        typography: typography,
      );
    }
    if (studioPreview) {
      return _StudioFace(
        sender: sender,
        relativeTime: relativeTime,
        showSender: preferences.showSender,
        showCaptions: preferences.showCaptions,
        accent: accent,
        typography: typography,
        theme: preferences.theme,
        backgroundTint: backgroundTint,
        momentSourceLabel: momentSourceLabel,
      );
    }
    return _FullFace(
      sender: sender,
      relativeTime: relativeTime,
      showSender: preferences.showSender,
      showTimestamp: preferences.showTimestamp,
      showCaptions: preferences.showCaptions,
      accent: accent,
      theme: preferences.theme,
      typography: typography,
      palette: palette,
    );
  }
}

class _PhotoBed extends StatelessWidget {
  const _PhotoBed({required this.theme, this.photoFirst = false});

  final WidgetTheme theme;
  final bool photoFirst;

  @override
  Widget build(BuildContext context) {
    if (photoFirst) return const _MomentPhotoMock();
    final palette = WidgetThemePalette.forTheme(theme);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.gradient,
        ),
      ),
    );
  }
}

/// Soft photo placeholder — warm tones, full bleed.
class _MomentPhotoMock extends StatelessWidget {
  const _MomentPhotoMock();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5C6B7A),
            Color(0xFFB87A5E),
            Color(0xFF8E5E42),
            Color(0xFF2A2220),
          ],
          stops: [0.0, 0.4, 0.72, 1.0],
        ),
      ),
    );
  }
}

/// Home Widget studio preview — photo-first with header + bottom sender row.
class _StudioFace extends StatelessWidget {
  const _StudioFace({
    required this.sender,
    required this.relativeTime,
    required this.showSender,
    required this.showCaptions,
    required this.accent,
    required this.typography,
    required this.theme,
    required this.backgroundTint,
    required this.momentSourceLabel,
  });

  final String sender;
  final String relativeTime;
  final bool showSender;
  final bool showCaptions;
  final Color accent;
  final WidgetTypography typography;
  final WidgetTheme theme;
  final double backgroundTint;
  final String momentSourceLabel;

  @override
  Widget build(BuildContext context) {
    final initial = sender.isNotEmpty ? sender[0].toUpperCase() : '?';
    final palette = WidgetThemePalette.forTheme(theme);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        _PhotoBed(theme: theme, photoFirst: true),
        ColoredBox(color: palette.overlayTop.withValues(alpha: backgroundTint.clamp(0, 0.85))),
        ColoredBox(color: accent.withValues(alpha: 0.08)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 72,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  palette.overlayBottom,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Row(
            children: [
              Text(
                '${theme.emoji}  ${theme.label}',
                style: WidgetTypographyStyles.label(
                  typography,
                  size: 11,
                  color: accent,
                  weight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                relativeTime,
                style: WidgetTypographyStyles.caption(
                  typography,
                  size: 10,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.9), width: 1.5),
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8C4A0), Color(0xFFC49A70)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: WidgetTypographyStyles.label(
                    typography,
                    size: 12,
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSender)
                      Text(
                        sender,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WidgetTypographyStyles.label(
                          typography,
                          size: 13,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                    if (showCaptions)
                      Text(
                        'A moment of peace',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WidgetTypographyStyles.caption(
                          typography,
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.8)),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Icon(Icons.favorite_border_rounded, size: 15, color: accent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FullFace extends StatelessWidget {
  const _FullFace({
    required this.sender,
    required this.relativeTime,
    required this.showSender,
    required this.showTimestamp,
    required this.showCaptions,
    required this.accent,
    required this.theme,
    required this.typography,
    required this.palette,
  });

  final String sender;
  final String relativeTime;
  final bool showSender;
  final bool showTimestamp;
  final bool showCaptions;
  final Color accent;
  final WidgetTheme theme;
  final WidgetTypography typography;
  final WidgetThemePalette palette;

  @override
  Widget build(BuildContext context) {
    final initial = sender.isNotEmpty ? sender[0].toUpperCase() : '?';

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        _PhotoBed(theme: theme, photoFirst: true),
        // Bottom scrim for readable overlay text
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 88,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.72),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Avatar — top left
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8C4A0), Color(0xFFC49A70)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: WidgetTypographyStyles.label(
                typography,
                size: 11,
                color: Colors.white,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // Bottom overlay — name, time, caption, heart
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSender)
                      Text(
                        sender,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WidgetTypographyStyles.label(
                          typography,
                          size: 14,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                    if (showTimestamp) ...[
                      SizedBox(height: 2),
                      Text(
                        relativeTime,
                        style: WidgetTypographyStyles.caption(
                          typography,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                    if (showCaptions) ...[
                      SizedBox(height: 2),
                      Text(
                        'A moment of peace',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WidgetTypographyStyles.caption(
                          typography,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 16,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlurFace extends StatelessWidget {
  const _BlurFace({
    required this.sender,
    required this.relativeTime,
    required this.showSender,
    required this.showTimestamp,
    required this.accent,
    required this.theme,
    required this.typography,
  });

  final String sender;
  final String relativeTime;
  final bool showSender;
  final bool showTimestamp;
  final Color accent;
  final WidgetTheme theme;
  final WidgetTypography typography;

  @override
  Widget build(BuildContext context) {
    final palette = WidgetThemePalette.forTheme(theme);
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: _PhotoBed(theme: theme, photoFirst: true),
        ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.32)),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSender)
                Text(
                  '${palette.emoji}  $sender',
                  style: WidgetTypographyStyles.label(
                    typography,
                    size: 10,
                    color: Colors.white,
                    weight: FontWeight.w600,
                  ),
                ),
              Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showSender)
                            Text(
                              sender,
                              style: WidgetTypographyStyles.label(
                                typography,
                                size: 12,
                                color: Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ),
                          if (showTimestamp)
                            Text(
                              relativeTime,
                              style: WidgetTypographyStyles.caption(
                                typography,
                                size: 10,
                                color: accent.withValues(alpha: 0.95),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.favorite_border_rounded,
                      color: palette.actionColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivateFace extends StatelessWidget {
  const _PrivateFace({
    required this.title,
    required this.from,
    required this.action,
    required this.typography,
  });

  final String title;
  final String from;
  final String action;
  final WidgetTypography typography;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF16121A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🌸  $title',
              style: WidgetTypographyStyles.caption(
                typography,
                size: 10,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6),
            Text(
              from,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WidgetTypographyStyles.label(
                typography,
                size: 12,
                color: Colors.white,
                weight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              action,
              style: WidgetTypographyStyles.caption(
                typography,
                size: 9,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryFace extends StatelessWidget {
  const _MemoryFace({required this.sender, required this.typography});

  final String sender;
  final WidgetTypography typography;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0B090E),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1 YEAR AGO',
              style: WidgetTypographyStyles.caption(
                typography,
                size: 9,
                color: Colors.white.withValues(alpha: 0.55),
              ).copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'You + $sender',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WidgetTypographyStyles.label(
                typography,
                size: 12,
                color: Colors.white,
                weight: FontWeight.w700,
              ),
            ),
            Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 72,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF8A5C), Color(0xFF7A3A4A)],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Relive →',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
