import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/core/widgets/moment_cached_image.dart';
import 'package:moment/core/widgets/moment_hero_tags.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';

class TinderMomentDeck extends StatefulWidget {
  const TinderMomentDeck({
    required this.moments,
    required this.index,
    required this.onNext,
    required this.onPrevious,
    required this.onOpen,
    required this.onReact,
    this.onPing,
    this.reacted = false,
    this.canPing = true,
    this.reactionEmoji = '😊',
    super.key,
  });

  final List<Moment> moments;
  final int index;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onOpen;
  final VoidCallback onReact;
  final VoidCallback? onPing;
  final bool reacted;
  final bool canPing;
  final String reactionEmoji;

  @override
  State<TinderMomentDeck> createState() => _TinderMomentDeckState();
}

class _TinderMomentDeckState extends State<TinderMomentDeck>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  late final AnimationController _settle;
  Animation<double>? _settleAnim;

  @override
  void initState() {
    super.initState();
    _settle =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 180),
        )..addListener(() {
          final value = _settleAnim?.value;
          if (value != null) setState(() => _dragX = value);
        });
  }

  @override
  void didUpdateWidget(covariant TinderMomentDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index ||
        oldWidget.moments.length != widget.moments.length) {
      _dragX = 0;
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.moments.isEmpty) return;
    setState(() => _dragX += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.moments.isEmpty) return;
    final width = MediaQuery.sizeOf(context).width;
    final goingRight = _dragX > 0;
    final canPrevious = goingRight && widget.index > 0;
    final canNext = !goingRight;
    final shouldSwipe =
        _dragX.abs() > width * 0.22 ||
        details.velocity.pixelsPerSecond.dx.abs() > 700;

    if (shouldSwipe && (canPrevious || canNext)) {
      final end = goingRight ? width : -width;
      _animateTo(
        end,
        onDone: () {
          _dragX = 0;
          if (goingRight) {
            widget.onPrevious();
          } else {
            widget.onNext();
          }
        },
      );
    } else {
      _animateTo(0);
    }
  }

  void _animateTo(double target, {VoidCallback? onDone}) {
    _settleAnim = Tween<double>(
      begin: _dragX,
      end: target,
    ).animate(CurvedAnimation(parent: _settle, curve: Curves.easeOutCubic));
    _settle.forward(from: 0).whenComplete(() {
      onDone?.call();
    });
  }

  Moment? _at(int offset) {
    final index = widget.index + offset;
    if (index < 0 || index >= widget.moments.length) return null;
    return widget.moments[index];
  }

  @override
  Widget build(BuildContext context) {
    final moments = widget.moments;
    if (moments.isEmpty) return const SizedBox.shrink();

    final rotation = (_dragX / 420).clamp(-0.18, 0.18);
    final remainingBehind = moments.length - widget.index - 1;
    final behindCount = remainingBehind.clamp(0, 2);

    return Padding(
      padding: EdgeInsets.only(bottom: behindCount * 12.0),
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            for (var i = behindCount; i >= 1; i--)
              if (_at(i) case final behind?)
                Positioned(
                  top: i * 12.0,
                  left: i * 8.0,
                  right: i * 8.0,
                  bottom: -i * 4.0,
                  child: Transform.scale(
                    scale: 1 - (i * 0.045),
                    child: MomentOverlayCard(moment: behind, dimmed: true),
                  ),
                ),
            GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: Transform.translate(
                offset: Offset(_dragX, 0),
                child: Transform.rotate(
                  angle: rotation,
                  child: MomentOverlayCard(
                    moment: moments[widget.index],
                    reacted: widget.reacted,
                    reactionEmoji: widget.reactionEmoji,
                    onOpen: widget.onOpen,
                    onReact: widget.onReact,
                    onPing: widget.canPing ? widget.onPing : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MomentOverlayCard extends StatelessWidget {
  const MomentOverlayCard({
    required this.moment,
    this.reacted = false,
    this.reactionEmoji = '😊',
    this.onOpen,
    this.onReact,
    this.onPing,
    this.dimmed = false,
    super.key,
  });

  final Moment moment;
  final bool reacted;
  final String reactionEmoji;
  final VoidCallback? onOpen;
  final VoidCallback? onReact;
  final VoidCallback? onPing;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final name = moment.sender.displayName;

    return GestureDetector(
      onTap: dimmed ? null : onOpen,
      child: Opacity(
        opacity: dimmed ? 0.92 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (moment.imageUrl == null)
                  ColoredBox(color: AppColors.photoPlaceholderDark)
                else if (dimmed)
                  MomentCachedImage(
                    imageUrl: moment.imageUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  Hero(
                    tag: MomentHeroTags.photo(
                      moment.id,
                      scope: MomentHeroTags.scopeHome,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: MomentCachedImage(
                        imageUrl: moment.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0xCC000000),
                      ],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 108,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if (reacted)
                              TextSpan(
                                text: '  $reactionEmoji',
                                style: const TextStyle(fontSize: 16),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        relativeTimeAgo(moment.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!dimmed)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onPing != null) ...[
                          _OverlayAction(label: '👋', onTap: onPing!),
                          const SizedBox(width: 8),
                        ],
                        _OverlayAction(
                          label: reacted ? reactionEmoji : '😊',
                          onTap: onReact,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayAction extends StatelessWidget {
  const _OverlayAction({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.46),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(label, style: const TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}
