import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';

/// Skeleton placeholders while a chat thread loads.
class ChatThreadShimmer extends StatelessWidget {
  const ChatThreadShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final base = context.mc.surfaceElevated;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _BubbleShimmer(color: base, alignRight: false, widthFactor: 0.62),
        _BubbleShimmer(color: base, alignRight: true, widthFactor: 0.48),
        _BubbleShimmer(color: base, alignRight: false, widthFactor: 0.55),
        _BubbleShimmer(color: base, alignRight: true, widthFactor: 0.58),
        _BubbleShimmer(color: base, alignRight: false, widthFactor: 0.42),
      ],
    );
  }
}

class _BubbleShimmer extends StatefulWidget {
  const _BubbleShimmer({
    required this.color,
    required this.alignRight,
    required this.widthFactor,
  });

  final Color color;
  final bool alignRight;
  final double widthFactor;

  @override
  State<_BubbleShimmer> createState() => _BubbleShimmerState();
}

class _BubbleShimmerState extends State<_BubbleShimmer>
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

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Align(
            alignment:
                widget.alignRight ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widget.widthFactor,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
