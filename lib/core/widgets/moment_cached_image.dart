import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';

/// Network image with disk/memory cache — avoids flashing the previous photo.
class MomentCachedImage extends StatelessWidget {
  const MomentCachedImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholderColor,
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    final fill = placeholderColor ?? AppColors.photoPlaceholderDark;
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: imageUrl,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: const Duration(milliseconds: 80),
      placeholder: (_, _) => ColoredBox(color: fill),
      errorWidget: (_, _, _) => ColoredBox(
        color: fill,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 20,
            color: AppColors.textTertiaryDark,
          ),
        ),
      ),
    );

    if (borderRadius == null) return image;

    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
