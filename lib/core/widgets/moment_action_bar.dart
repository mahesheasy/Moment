import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/widgets/moment_avatar.dart';

class MomentActionBar extends StatelessWidget {
  const MomentActionBar({
    required this.onPing,
    required this.onReact,
    required this.onCamera,
    this.reacted = false,
    super.key,
  });

  final VoidCallback onPing;
  final VoidCallback onReact;
  final VoidCallback onCamera;
  final bool reacted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(emoji: '👋', onTap: onPing),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            emoji: '❤️',
            onTap: onReact,
            highlighted: reacted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(emoji: '📷', onTap: onCamera),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.emoji,
    required this.onTap,
    this.highlighted = false,
  });

  final String emoji;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted
          ? AppColors.violet.withValues(alpha: 0.18)
          : AppColors.surfaceElevatedDark,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.45),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
}

class OverlappingAvatars extends StatelessWidget {
  const OverlappingAvatars({
    required this.imageUrls,
    required this.names,
    this.ringColors = const [],
    this.size = 36,
    super.key,
  });

  final List<String?> imageUrls;
  final List<String> names;
  final List<Color> ringColors;
  final double size;

  @override
  Widget build(BuildContext context) {
    final count = imageUrls.length.clamp(1, 2);
    final width = size + (count - 1) * (size * 0.62);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: i * (size * 0.62),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i < ringColors.length
                        ? ringColors[i]
                        : AppColors.surfaceDark,
                    width: 2,
                  ),
                ),
                child: MomentAvatar(
                  name: i < names.length ? names[i] : null,
                  imageUrl: imageUrls[i],
                  size: size - 4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
