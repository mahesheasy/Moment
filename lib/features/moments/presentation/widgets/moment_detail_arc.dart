import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/features/moments/domain/moment_decorations.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';

enum MomentDetailType { location, weather, stickers, review, time }

extension MomentDetailTypeX on MomentDetailType {
  static const List<MomentDetailType> arcOrder = [
    MomentDetailType.location,
    MomentDetailType.weather,
    MomentDetailType.stickers,
    MomentDetailType.review,
    MomentDetailType.time,
  ];

  int get arcIndex => arcOrder.indexOf(this);

  static MomentDetailType fromIndex(int index) =>
      arcOrder[index.clamp(0, arcOrder.length - 1)];

  String get title => switch (this) {
    MomentDetailType.location => 'Location',
    MomentDetailType.weather => 'Weather',
    MomentDetailType.stickers => 'Stickers',
    MomentDetailType.review => 'Review',
    MomentDetailType.time => 'Time',
  };

  IconData get icon => switch (this) {
    MomentDetailType.location => Icons.location_on_outlined,
    MomentDetailType.weather => Icons.cloud_outlined,
    MomentDetailType.stickers => Icons.emoji_emotions_outlined,
    MomentDetailType.review => Icons.star_outline_rounded,
    MomentDetailType.time => Icons.schedule_outlined,
  };

  IconData get selectedIcon => switch (this) {
    MomentDetailType.location => Icons.location_on_rounded,
    MomentDetailType.weather => Icons.cloud_rounded,
    MomentDetailType.stickers => Icons.emoji_emotions_rounded,
    MomentDetailType.review => Icons.star_rounded,
    MomentDetailType.time => Icons.schedule_rounded,
  };
}

class MomentDetailArcItem {
  const MomentDetailArcItem({
    required this.type,
    required this.subtitle,
    required this.semanticValue,
    this.hasValue = false,
  });

  final MomentDetailType type;
  final String subtitle;
  final String semanticValue;
  final bool hasValue;
}

List<MomentDetailArcItem> momentDetailArcItems(CameraState state) {
  final loading = state.isLoadingContext;

  String locationSubtitle;
  if (loading) {
    locationSubtitle = 'Loading…';
  } else if (state.includeLocation && state.locationLabel != null) {
    locationSubtitle = _shortLocation(state.locationLabel!);
  } else if (state.locationLabel != null) {
    locationSubtitle = 'Add location';
  } else {
    locationSubtitle = 'Where was this?';
  }

  String weatherSubtitle;
  if (loading) {
    weatherSubtitle = 'Loading…';
  } else if (state.includeWeather && state.weatherLabel != null) {
    weatherSubtitle = state.weatherLabel!;
  } else if (state.weatherLabel != null) {
    weatherSubtitle = 'Add weather';
  } else {
    weatherSubtitle = "How's the weather?";
  }

  final stickerSubtitle = state.decorations.isEmpty
      ? 'Pick one sticker'
      : MomentDecorations.displayLabel(state.decorations.first);

  String reviewSubtitle;
  if (state.reviewRating > 0) {
    reviewSubtitle =
        '${state.reviewRating} star${state.reviewRating == 1 ? '' : 's'}';
    if (state.reviewText.trim().isNotEmpty) {
      reviewSubtitle = state.reviewText.trim();
    }
  } else {
    reviewSubtitle = 'Rate this moment';
  }

  final timeSubtitle = state.timeLabel == null
      ? 'Add time'
      : state.includeTime
      ? state.timeLabel!
      : 'Tap to add ${state.timeLabel!}';

  return [
    MomentDetailArcItem(
      type: MomentDetailType.location,
      subtitle: locationSubtitle,
      semanticValue: locationSubtitle,
      hasValue: state.includeLocation,
    ),
    MomentDetailArcItem(
      type: MomentDetailType.weather,
      subtitle: weatherSubtitle,
      semanticValue: weatherSubtitle,
      hasValue: state.includeWeather,
    ),
    MomentDetailArcItem(
      type: MomentDetailType.stickers,
      subtitle: stickerSubtitle,
      semanticValue: stickerSubtitle,
      hasValue: state.decorations.isNotEmpty,
    ),
    MomentDetailArcItem(
      type: MomentDetailType.review,
      subtitle: reviewSubtitle,
      semanticValue: reviewSubtitle,
      hasValue: state.reviewRating > 0,
    ),
    MomentDetailArcItem(
      type: MomentDetailType.time,
      subtitle: timeSubtitle,
      semanticValue: timeSubtitle,
      hasValue: state.includeTime,
    ),
  ];
}

String _shortLocation(String label) {
  final parts = label.split(',');
  if (parts.length <= 2) return label;
  return '${parts.first.trim()}, ${parts[1].trim()}';
}

class ArcGeometry {
  ArcGeometry({
    required this.width,
    required this.height,
    required this.itemCount,
  }) : centerX = width * 0.5,
       arcCenterY = height + height * 0.42,
       radius = width * 0.44,
       itemSpacing = math.pi / (itemCount + 0.85),
       maxArcAngle = math.pi * 0.46;

  final double width;
  final double height;
  final int itemCount;
  final double centerX;
  final double arcCenterY;
  final double radius;
  final double itemSpacing;
  final double maxArcAngle;

  Offset positionFor(int index, double focusIndex) {
    final angle = (index - focusIndex) * itemSpacing;
    return Offset(
      centerX + radius * math.sin(angle),
      arcCenterY - radius * math.cos(angle),
    );
  }

  double nodeSizeFor(int index, double focusIndex) {
    final distance = (index - focusIndex).abs();
    if (distance < 0.35) return 50;
    if (distance < 1.1) return 40;
    if (distance < 2.1) return 34;
    return 30;
  }

  double opacityFor(int index, double focusIndex) {
    final distance = (index - focusIndex).abs();
    return (1.0 - distance * 0.18).clamp(0.32, 1.0);
  }

  bool isSelected(int index, double focusIndex) =>
      (index - focusIndex).abs() < 0.35;
}

class MomentDetailArc extends StatefulWidget {
  const MomentDetailArc({
    required this.items,
    required this.onSelected,
    this.initialType = MomentDetailType.review,
    super.key,
  });

  final List<MomentDetailArcItem> items;
  final ValueChanged<MomentDetailType> onSelected;
  final MomentDetailType initialType;

  @override
  State<MomentDetailArc> createState() => _MomentDetailArcState();
}

class _MomentDetailArcState extends State<MomentDetailArc>
    with SingleTickerProviderStateMixin {
  static const double _dragSensitivity = 54;
  static const int _defaultIndex = 3;

  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  double _focusIndex = _defaultIndex.toDouble();
  double _dragFocus = _defaultIndex.toDouble();
  double _dragOrigin = _defaultIndex.toDouble();
  double _dragDelta = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _focusIndex = widget.initialType.arcIndex.toDouble();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _snapAnimation = AlwaysStoppedAnimation(_focusIndex);
    _snapController.addListener(_onSnapTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelected(MomentDetailTypeX.fromIndex(_focusIndex.round()));
    });
  }

  @override
  void dispose() {
    _snapController
      ..removeListener(_onSnapTick)
      ..dispose();
    super.dispose();
  }

  void _onSnapTick() {
    setState(() {
      _focusIndex = _snapAnimation.value;
    });
  }

  double get _renderFocus => _isDragging ? _dragFocus : _snapAnimation.value;

  int get _selectedIndex =>
      _renderFocus.round().clamp(0, widget.items.length - 1);

  MomentDetailArcItem get _selectedItem => widget.items[_selectedIndex];

  void _animateToIndex(int index) {
    final target = index.clamp(0, widget.items.length - 1).toDouble();
    _snapAnimation = Tween<double>(begin: _focusIndex, end: target).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.forward(from: 0);
    widget.onSelected(MomentDetailTypeX.fromIndex(target.round()));
  }

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _dragOrigin = _snapAnimation.value;
    _dragFocus = _dragOrigin;
    _dragDelta = 0;
    _snapController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragDelta += details.primaryDelta ?? details.delta.dx;
    final next = (_dragOrigin - _dragDelta / _dragSensitivity).clamp(
      0.0,
      (widget.items.length - 1).toDouble(),
    );
    setState(() => _dragFocus = next);
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    var target = _dragFocus.round();

    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity.abs() > 700) {
      if (velocity < 0) {
        target = (_dragFocus + 0.55).ceil();
      } else {
        target = (_dragFocus - 0.55).floor();
      }
    }

    target = target.clamp(0, widget.items.length - 1);
    _focusIndex = _dragFocus;
    _animateToIndex(target);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem;

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SelectedHeader(item: selected),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final geometry = ArcGeometry(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  itemCount: widget.items.length,
                );
                final focus = _renderFocus;

                final indices = List.generate(widget.items.length, (i) => i);
                indices.sort(
                  (a, b) => (a - focus).abs().compareTo((b - focus).abs()),
                );

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      CustomPaint(
                        size: Size(geometry.width, geometry.height),
                        painter: MomentDetailArcPainter(
                          geometry: geometry,
                          focusIndex: focus,
                        ),
                      ),
                      for (final i in indices)
                        _ArcNode(
                          item: widget.items[i],
                          position: geometry.positionFor(i, focus),
                          size: geometry.nodeSizeFor(i, focus),
                          opacity: geometry.opacityFor(i, focus),
                          selected: geometry.isSelected(i, focus),
                          onTap: () => _animateToIndex(i),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedHeader extends StatelessWidget {
  const _SelectedHeader({required this.item});

  final MomentDetailArcItem item;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Column(
        key: ValueKey(item.type),
        children: [
          Text(
            item.type.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTertiaryDark,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcNode extends StatelessWidget {
  const _ArcNode({
    required this.item,
    required this.position,
    required this.size,
    required this.opacity,
    required this.selected,
    required this.onTap,
  });

  final MomentDetailArcItem item;
  final Offset position;
  final double size;
  final double opacity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hitSize = math.max(size, 44.0);

    return Positioned(
      left: position.dx - hitSize / 2,
      top: position.dy - hitSize / 2,
      width: hitSize,
      height: hitSize,
      child: Semantics(
        button: true,
        label: '${item.type.title}. ${item.semanticValue}',
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Opacity(
            opacity: opacity,
            child: Center(
              child: _ArcNodeCircle(
                icon: selected ? item.type.selectedIcon : item.type.icon,
                selected: selected,
                hasValue: item.hasValue,
                size: size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcNodeCircle extends StatelessWidget {
  const _ArcNodeCircle({
    required this.icon,
    required this.selected,
    required this.hasValue,
    required this.size,
  });

  final IconData icon;
  final bool selected;
  final bool hasValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? AppColors.violet.withValues(alpha: 0.24)
            : const Color(0xFF16161A).withValues(alpha: 0.92),
        border: Border.all(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: hasValue ? 0.3 : 0.1),
          width: selected ? 2.2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.4),
                  blurRadius: 14,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: selected ? 23 : size * 0.46,
        color: selected ? AppColors.violet : Colors.white54,
      ),
    );
  }
}

class MomentDetailArcPainter extends CustomPainter {
  MomentDetailArcPainter({required this.geometry, required this.focusIndex});

  final ArcGeometry geometry;
  final double focusIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(geometry.centerX, geometry.arcCenterY);
    final rect = Rect.fromCircle(center: center, radius: geometry.radius);
    final startAngle = -math.pi / 2 - geometry.maxArcAngle;
    final sweepAngle = geometry.maxArcAngle * 2;

    final arcGradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        AppColors.photoPink.withValues(alpha: 0.85),
        const Color(0xFFC4A1FF).withValues(alpha: 0.75),
        AppColors.sendCoral.withValues(alpha: 0.8),
        AppColors.photoPink.withValues(alpha: 0.85),
      ],
      stops: const [0.0, 0.4, 0.72, 1.0],
      transform: GradientRotation(startAngle),
    );

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..shader = arcGradient.createShader(rect);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..shader = arcGradient.createShader(rect);

    canvas.drawArc(rect, startAngle, sweepAngle, false, linePaint);

    for (var i = 0; i < geometry.itemCount; i++) {
      final angle = (i - focusIndex) * geometry.itemSpacing;
      if (angle.abs() > geometry.maxArcAngle + 0.15) continue;

      final dot = Offset(
        center.dx + geometry.radius * math.sin(angle),
        center.dy - geometry.radius * math.cos(angle),
      );
      canvas.drawCircle(
        dot,
        selectedDotRadius(i, focusIndex),
        Paint()
          ..color = Colors.white.withValues(
            alpha: geometry.isSelected(i, focusIndex) ? 0.55 : 0.14,
          ),
      );
    }
  }

  double selectedDotRadius(int index, double focus) {
    if ((index - focus).abs() < 0.35) return 2.4;
    return 1.4;
  }

  @override
  bool shouldRepaint(covariant MomentDetailArcPainter oldDelegate) =>
      oldDelegate.geometry.width != geometry.width ||
      oldDelegate.geometry.height != geometry.height ||
      oldDelegate.focusIndex != focusIndex;
}
