import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_radius.dart';

abstract final class MemoryHeroTags {
  static String cover(String memoryId) => 'memory-cover-$memoryId';
}

class MemoryCoverImage extends StatelessWidget {
  const MemoryCoverImage({
    required this.imageUrl,
    this.height,
    this.aspectRatio,
    this.borderRadius,
    super.key,
  });

  final String? imageUrl;
  final double? height;
  final double? aspectRatio;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl == null
        ? ColoredBox(color: AppColors.photoPlaceholderDark)
        : Image.network(imageUrl!, fit: BoxFit.cover);

    Widget child = image;
    if (aspectRatio != null) {
      child = AspectRatio(aspectRatio: aspectRatio!, child: image);
    } else if (height != null) {
      child = SizedBox(height: height, width: double.infinity, child: image);
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return child;
  }
}

class MemoryCoverHero extends StatelessWidget {
  const MemoryCoverHero({
    required this.memoryId,
    required this.imageUrl,
    this.height,
    this.aspectRatio,
    this.borderRadius,
    super.key,
  });

  final String memoryId;
  final String? imageUrl;
  final double? height;
  final double? aspectRatio;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: MemoryHeroTags.cover(memoryId),
      child: Material(
        color: Colors.transparent,
        child: MemoryCoverImage(
          imageUrl: imageUrl,
          height: height,
          aspectRatio: aspectRatio,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class MemoryDeleteIconButton extends StatelessWidget {
  const MemoryDeleteIconButton({
    required this.onPressed,
    this.compact = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 10),
          child: Icon(
            Icons.delete_outline_rounded,
            size: compact ? 18 : 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class MemoryDarkPanel extends StatelessWidget {
  const MemoryDarkPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderDark),
      ),
      child: child,
    );
  }
}
