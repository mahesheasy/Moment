import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/moments/domain/moment_decorations.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';

/// Live photo preview — selections appear as overlays on the moment.
class MomentPhotoPreview extends StatelessWidget {
  const MomentPhotoPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CameraCubit>().state;
    final bytes = state.imageBytes;

    return ClipRRect(
      borderRadius: AppRadius.xxxlAll,
      child: bytes == null
          ? MomentShimmer(
              child: ColoredBox(color: AppColors.photoPlaceholderDark),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  bytes,
                  key: ValueKey(state.previewRevision),
                  fit: BoxFit.cover,
                  gaplessPlayback: false,
                ),
                const _PhotoVignette(),
                ..._momentOverlayLayers(state),
              ],
            ),
    );
  }

  List<Widget> _momentOverlayLayers(CameraState state) {
    final layers = <Widget>[];

    if (state.includeLocation && state.locationLabel != null) {
      layers.add(
        Positioned(
          top: 12,
          left: 12,
          child: _MomentBadge(
            icon: Icons.location_on_rounded,
            label: _short(state.locationLabel!),
          ),
        ),
      );
    }

    if (state.includeWeather && state.weatherLabel != null) {
      layers.add(
        Positioned(
          top: 12,
          right: 12,
          child: _MomentBadge(
            icon: Icons.cloud_rounded,
            label: state.weatherLabel!,
          ),
        ),
      );
    }

    if (state.includeTime && state.timeLabel != null) {
      layers.add(
        Positioned(
          top: 48,
          left: 12,
          child: _MomentBadge(
            icon: Icons.schedule_rounded,
            label: state.timeLabel!,
          ),
        ),
      );
    }

    if (state.includeStreak && state.streakCount > 0) {
      layers.add(
        Positioned(
          top: 48,
          right: 12,
          child: _MomentBadge(
            leading: '🔥',
            label: '${state.streakCount}d',
            accent: true,
          ),
        ),
      );
    }

    if (state.reviewRating > 0) {
      layers.add(
        Positioned(
          top: 84,
          left: 12,
          child: _MomentBadge(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= state.reviewRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFB020),
                    size: 15,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final stickerTags = state.decorations.toList();
    for (var i = 0; i < stickerTags.length; i++) {
      final tag = stickerTags[i];
      final style = MomentDecorations.pillStyle(tag);
      layers.add(
        Positioned(
          top: 110 + (i % 2) * 36.0,
          right: 12 + (i % 3) * 8.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: style.background,
              gradient: style.gradient,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              '${MomentDecorations.emojiFor(tag)} ${MomentDecorations.displayLabel(tag)}',
              style: TextStyle(
                color: style.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    if (state.reviewText.trim().isNotEmpty) {
      layers.add(
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Text(
            state.reviewText.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.25,
              shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
            ),
          ),
        ),
      );
    }

    return layers;
  }

  static String _short(String label) {
    final parts = label.split(',');
    return parts.first.trim();
  }
}

class _PhotoVignette extends StatelessWidget {
  const _PhotoVignette();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.18, 0.72, 1],
          colors: [
            Color(0x99000000),
            Colors.transparent,
            Colors.transparent,
            Color(0xCC000000),
          ],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _MomentBadge extends StatelessWidget {
  const _MomentBadge({
    this.label,
    this.icon,
    this.leading,
    this.child,
    this.accent = false,
  });

  final String? label;
  final IconData? icon;
  final String? leading;
  final Widget? child;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent
            ? const Color(0xFFFFD54F).withValues(alpha: 0.95)
            : Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child:
          child ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Text(leading!, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
              ],
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: accent ? const Color(0xFF3D2800) : Colors.white,
                ),
                const SizedBox(width: 4),
              ],
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    color: accent ? const Color(0xFF3D2800) : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
    );
  }
}
