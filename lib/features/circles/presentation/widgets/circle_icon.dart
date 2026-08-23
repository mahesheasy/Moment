import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/widgets/moment_cached_image.dart';
import 'package:moment/features/circles/data/circle_image_resolver.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';

/// Circle list/detail icon — custom photo or default emoji.
class CircleIcon extends StatefulWidget {
  const CircleIcon({
    required this.circle,
    this.size = 44,
    this.radius = 14,
    this.imageCacheKey = 0,
    super.key,
  });

  final Circle circle;
  final double size;
  final double radius;
  final int imageCacheKey;

  @override
  State<CircleIcon> createState() => _CircleIconState();
}

class _CircleIconState extends State<CircleIcon> {
  String? _resolvedUrl;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(CircleIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circle.avatarUrl != widget.circle.avatarUrl ||
        oldWidget.imageCacheKey != widget.imageCacheKey) {
      _failed = false;
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    final source = widget.circle.avatarUrl;
    if (source == null || source.trim().isEmpty) {
      if (mounted) setState(() => _resolvedUrl = null);
      return;
    }

    if (CircleImageResolver.isNetworkUrl(source)) {
      if (mounted) setState(() => _resolvedUrl = source);
      return;
    }

    sl<CircleImageResolver>().invalidate(source);
    final resolved = await sl<CircleImageResolver>().resolve(source);
    if (!mounted) return;
    setState(() {
      _resolvedUrl = resolved;
      _failed = resolved == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: _resolvedUrl != null && !_failed
          ? MomentCachedImage(
              imageUrl: _resolvedUrl!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            )
          : _emojiFallback(),
    );
  }

  Widget _emojiFallback() {
    return Text(
      widget.circle.displayEmoji,
      style: TextStyle(fontSize: widget.size * 0.48, height: 1),
    );
  }
}
