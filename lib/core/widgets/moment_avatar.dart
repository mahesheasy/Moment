import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/features/profile/data/avatar_url_resolver.dart';

class MomentAvatar extends StatefulWidget {
  const MomentAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 44,
    this.showBorder = false,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final bool showBorder;

  @override
  State<MomentAvatar> createState() => _MomentAvatarState();
}

class _MomentAvatarState extends State<MomentAvatar> {
  String? _resolvedUrl;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(MomentAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _failed = false;
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    final source = widget.imageUrl;
    if (source == null || source.trim().isEmpty) {
      if (mounted) setState(() => _resolvedUrl = null);
      return;
    }

    if (AvatarUrlResolver.isNetworkUrl(source)) {
      if (mounted) setState(() => _resolvedUrl = source);
      return;
    }

    final resolved = await sl<AvatarUrlResolver>().resolve(source);
    if (!mounted) return;
    setState(() {
      _resolvedUrl = resolved;
      _failed = resolved == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.accentSoft,
        border: widget.showBorder
            ? Border.all(
                color: isDark ? AppColors.borderDark : AppColors.surface,
                width: 2,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: _resolvedUrl != null && !_failed
          ? Image.network(
              _resolvedUrl!,
              fit: BoxFit.cover,
              width: widget.size,
              height: widget.size,
              errorBuilder: (_, _, _) =>
                  _initialsWidget(_initialsText(widget.name), isDark),
            )
          : _initialsWidget(_initialsText(widget.name), isDark),
    );
  }

  Widget _initialsWidget(String initials, bool isDark) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: isDark ? AppColors.violet : AppColors.accent,
          fontSize: widget.size * 0.36,
        ),
      ),
    );
  }

  String _initialsText(String? value) {
    if (value == null || value.trim().isEmpty) return '?';
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}

class MomentImage extends StatelessWidget {
  const MomentImage({
    super.key,
    this.imageUrl,
    this.aspectRatio = 4 / 5,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final double aspectRatio;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: borderRadius ?? AppRadius.xlAll,
        child: imageUrl != null && AvatarUrlResolver.isNetworkUrl(imageUrl)
            ? Image.network(imageUrl!, fit: fit)
            : const _Placeholder(aspectRatio: 4 / 5),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.aspectRatio});

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.photoPlaceholder,
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          size: 48,
          color: AppColors.textTertiary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
