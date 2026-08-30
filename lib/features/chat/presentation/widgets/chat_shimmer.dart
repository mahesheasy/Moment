import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';

/// Skeleton that mirrors the real chat inbox layout (tiles + section header).
class ChatInboxShimmer extends StatelessWidget {
  const ChatInboxShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final base = context.mc.surfaceElevated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: _ShimmerBox(
            color: base,
            width: 72,
            height: 12,
            radius: 6,
          ),
        ),
        for (var i = 0; i < 7; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _ShimmerInboxTile(color: base),
          ),
      ],
    );
  }
}

class _ShimmerInboxTile extends StatefulWidget {
  const _ShimmerInboxTile({required this.color});

  final Color color;

  @override
  State<_ShimmerInboxTile> createState() => _ShimmerInboxTileState();
}

class _ShimmerInboxTileState extends State<_ShimmerInboxTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.42 + (_controller.value * 0.38);
        final color = widget.color.withValues(alpha: opacity);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ShimmerBox(color: color, width: 50, height: 50, radius: 25),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ShimmerBox(color: color, width: 120, height: 13, radius: 6),
                      const Spacer(),
                      _ShimmerBox(color: color, width: 36, height: 11, radius: 6),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ShimmerBox(
                    color: color,
                    width: double.infinity,
                    height: 12,
                    radius: 6,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.color,
    required this.width,
    required this.height,
    required this.radius,
  });

  final Color color;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
