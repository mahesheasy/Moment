import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:moment/core/widgets/moment_media_privacy_preview.dart';

/// One card in the home-widget stack preview.
class WidgetStackPreviewMoment {
  const WidgetStackPreviewMoment({
    required this.id,
    required this.title,
    required this.relativeTime,
    this.streakCount = 0,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String relativeTime;
  final int streakCount;
  final String? imageUrl;
}

/// Swipeable stacked-deck interaction for the home-widget preview.
class WidgetMomentStack extends StatefulWidget {
  const WidgetMomentStack({
    required this.moments,
    required this.cardBuilder,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.privacyEnabled = true,
    super.key,
  });

  final List<WidgetStackPreviewMoment> moments;
  final Widget Function(
    BuildContext context,
    WidgetStackPreviewMoment moment,
    bool isFront,
  ) cardBuilder;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final bool privacyEnabled;

  @override
  State<WidgetMomentStack> createState() => _WidgetMomentStackState();
}

class _WidgetMomentStackState extends State<WidgetMomentStack>
    with TickerProviderStateMixin {
  late int _index;
  double _dragX = 0;
  double _stackWidth = 240;
  late final AnimationController _settle;
  Animation<double>? _settleAnim;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, math.max(0, widget.moments.length - 1));
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        final value = _settleAnim?.value;
        if (value != null && mounted) setState(() => _dragX = value);
      });
  }

  @override
  void didUpdateWidget(covariant WidgetMomentStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moments == widget.moments) return;

    final viewingId =
        oldWidget.moments.isEmpty
            ? null
            : oldWidget.moments[
                _index.clamp(0, math.max(0, oldWidget.moments.length - 1))
              ].id;
    if (viewingId != null) {
      final nextIndex = widget.moments.indexWhere((m) => m.id == viewingId);
      _index =
          nextIndex >= 0
              ? nextIndex
              : _index.clamp(0, math.max(0, widget.moments.length - 1));
    } else {
      _index = _index.clamp(0, math.max(0, widget.moments.length - 1));
    }
    _dragX = 0;
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  WidgetStackPreviewMoment? _at(int offset) {
    final target = _index + offset;
    if (target < 0 || target >= widget.moments.length) return null;
    return widget.moments[target];
  }

  double _depthScale(int depth, double dragProgress) {
    final base = switch (depth) {
      1 => 0.97,
      2 => 0.93,
      _ => 0.90,
    };
    if (depth == 1) return base + (dragProgress * 0.03);
    if (depth == 2) return base + (dragProgress * 0.02);
    return base;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.moments.length <= 1) return;
    setState(() => _dragX += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.moments.length <= 1) return;
    final width = _stackWidth;
    final goingRight = _dragX > 0;
    final canPrevious = goingRight && _index > 0;
    final canNext = !goingRight && _index < widget.moments.length - 1;
    final shouldSwipe =
        _dragX.abs() > width * 0.18 ||
        details.velocity.pixelsPerSecond.dx.abs() > 550;

    if (shouldSwipe && (canPrevious || canNext)) {
      final end = goingRight ? width : -width;
      _animateTo(
        end,
        onDone: () {
          if (!mounted) return;
          setState(() {
            _dragX = 0;
            _index += goingRight ? -1 : 1;
          });
          widget.onIndexChanged?.call(_index);
        },
      );
    } else {
      _animateTo(0);
    }
  }

  void _animateTo(double target, {VoidCallback? onDone}) {
    _settleAnim = Tween<double>(begin: _dragX, end: target).animate(
      CurvedAnimation(parent: _settle, curve: Curves.easeOutCubic),
    );
    _settle.forward(from: 0).whenComplete(onDone ?? () {});
  }

  @override
  Widget build(BuildContext context) {
    final moments = widget.moments;
    if (moments.isEmpty) return const SizedBox.shrink();
    if (moments.length == 1) {
      final only = moments.first;
      final card = widget.cardBuilder(context, only, true);
      if (!widget.privacyEnabled) return card;
      return MomentMediaPrivacyPreview(
        key: ValueKey(only.id),
        child: card,
      );
    }

    final front = moments[_index];
    final rotation = (_dragX / 340).clamp(-0.14, 0.14);
    final behindCount = math.min(2, moments.length - _index - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 240.0;
        _stackWidth = width;
        final dragProgress = (_dragX.abs() / width).clamp(0.0, 1.0);

        return Padding(
          padding: EdgeInsets.only(
            top: behindCount * 6.0,
            right: behindCount * 5.0,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              for (var depth = behindCount; depth >= 1; depth--)
                if (_at(depth) case final behind?)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(depth * 8.0, -depth * 6.0),
                      child: Transform.scale(
                        scale: _depthScale(depth, dragProgress),
                        alignment: Alignment.topRight,
                        child: Transform.rotate(
                          angle: depth * 0.022,
                          child: Opacity(
                            opacity: 0.92 - (depth * 0.10),
                            child: widget.cardBuilder(context, behind, false),
                          ),
                        ),
                      ),
                    ),
                  ),
              GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: Transform.translate(
                  offset: Offset(_dragX, 0),
                  child: Transform.rotate(
                    angle: rotation,
                    child: widget.privacyEnabled
                        ? MomentMediaPrivacyPreview(
                            key: ValueKey(front.id),
                            child: widget.cardBuilder(context, front, true),
                          )
                        : widget.cardBuilder(context, front, true),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
