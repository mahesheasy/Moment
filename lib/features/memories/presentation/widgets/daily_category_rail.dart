import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_cached_image.dart';
import 'package:moment/core/widgets/moment_hero_tags.dart';
import 'package:moment/features/memories/domain/entities/daily_category.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

typedef MomentMenuCallback = void Function(Moment moment);

class DailyCategoryRail extends StatefulWidget {
  const DailyCategoryRail({
    required this.category,
    required this.onOpenMoment,
    this.onMomentMenu,
    this.reactionsByMomentId = const {},
    super.key,
  });

  final DailyCategory category;
  final ValueChanged<Moment> onOpenMoment;
  final MomentMenuCallback? onMomentMenu;
  final Map<String, MomentReactionSummary> reactionsByMomentId;

  @override
  State<DailyCategoryRail> createState() => _DailyCategoryRailState();
}

class _DailyCategoryRailState extends State<DailyCategoryRail>
    with SingleTickerProviderStateMixin {
  var _index = 0;
  var _dragX = 0.0;
  late final AnimationController _settle;
  Animation<double>? _settleAnim;

  List<Moment> get _moments => widget.category.moments;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
      final value = _settleAnim?.value;
      if (value != null) setState(() => _dragX = value);
    });
  }

  @override
  void didUpdateWidget(covariant DailyCategoryRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category.id != widget.category.id) {
      _index = 0;
      _dragX = 0;
      return;
    }
    if (oldWidget.category.moments.length != widget.category.moments.length) {
      _dragX = 0;
      _index = _index.clamp(0, _moments.length - 1);
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_moments.length < 2) return;
    setState(() => _dragX += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_moments.length < 2) return;
    final width = MediaQuery.sizeOf(context).width;
    final goingRight = _dragX > 0;
    final canPrevious = goingRight && _index > 0;
    final canNext = !goingRight && _index < _moments.length - 1;
    final shouldSwipe =
        _dragX.abs() > width * 0.18 ||
        details.velocity.pixelsPerSecond.dx.abs() > 650;

    if (shouldSwipe && (canPrevious || canNext)) {
      _animateTo(goingRight ? width * 1.15 : -width * 1.15, onDone: () {
        setState(() {
          _dragX = 0;
          _index += goingRight ? -1 : 1;
        });
      });
    } else {
      _animateTo(0);
    }
  }

  void _animateTo(double target, {VoidCallback? onDone}) {
    _settleAnim = Tween<double>(begin: _dragX, end: target).animate(
      CurvedAnimation(parent: _settle, curve: Curves.easeOutCubic),
    );
    _settle.forward(from: 0).whenComplete(() => onDone?.call());
  }

  Moment? _at(int offset) {
    final index = _index + offset;
    if (index < 0 || index >= _moments.length) return null;
    return _moments[index];
  }

  @override
  Widget build(BuildContext context) {
    final moments = _moments;
    if (moments.isEmpty) return const SizedBox.shrink();

    final remaining = moments.length - _index - 1;
    final behindCount = remaining.clamp(0, 2);
    final rotation = (_dragX / 480).clamp(-0.14, 0.14);
    final category = widget.category;
    final current = moments[_index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CategoryAvatar(category: category),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SettingsType.body(Colors.white).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  if (category.subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      category.subtitle!,
                      style: SettingsType.caption(
                        AppColors.textTertiaryDark,
                      ).copyWith(fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            if (moments.length > 1)
              Text(
                '${_index + 1} of ${moments.length}',
                style: SettingsType.caption(
                  AppColors.textTertiaryDark,
                ).copyWith(fontSize: 10),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, behindCount * 8.0),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                for (var i = behindCount; i >= 1; i--)
                  if (_at(i) case final behind?)
                    Positioned(
                      top: i * 10.0,
                      left: i * 8.0,
                      right: i * 8.0,
                      bottom: -i * 5.0,
                      child: Transform.scale(
                        scale: 1 - (i * 0.035),
                        child: _MomentCard(moment: behind, dimmed: true),
                      ),
                    ),
                GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  onTap: () => widget.onOpenMoment(current),
                  child: Transform.translate(
                    offset: Offset(_dragX, _dragX.abs() * 0.03),
                    child: Transform.rotate(
                      angle: rotation,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.96, end: 1)
                                  .animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _MomentCard(
                          key: ValueKey(current.id),
                          moment: current,
                          heroEnabled: true,
                          reactions: widget.reactionsByMomentId[current.id],
                          onMenu: widget.onMomentMenu == null
                              ? null
                              : () => widget.onMomentMenu!(current),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryAvatar extends StatelessWidget {
  const _CategoryAvatar({required this.category});

  final DailyCategory category;

  @override
  Widget build(BuildContext context) {
    if (category.kind == DailyCategoryKind.person) {
      return MomentAvatar(
        name: category.title,
        imageUrl: category.avatarUrl,
        size: 28,
      );
    }

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
      ),
      child: Text(
        category.emoji ?? '👥',
        style: const TextStyle(fontSize: 13, height: 1),
      ),
    );
  }
}

class _ReactionPill extends StatelessWidget {
  const _ReactionPill({required this.summary});

  final MomentReactionSummary? summary;

  @override
  Widget build(BuildContext context) {
    if (summary == null || summary!.total == 0) {
      return const SizedBox.shrink();
    }

    final sorted = summary!.counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final emojis = sorted.take(3).map((e) => e.key.emoji).join();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emojis, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 3),
            Text(
              '${summary!.total}',
              style: SettingsType.caption(Colors.white).copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.moment,
    this.dimmed = false,
    this.heroEnabled = false,
    this.onMenu,
    this.reactions,
    super.key,
  });

  final Moment moment;
  final bool dimmed;
  final bool heroEnabled;
  final VoidCallback? onMenu;
  final MomentReactionSummary? reactions;

  @override
  Widget build(BuildContext context) {
    final caption = moment.caption?.trim();
    final hasCaption = caption != null && caption.isNotEmpty;
    final headline = hasCaption ? caption : moment.sender.displayName;
    final meta = hasCaption
        ? '${moment.sender.displayName} · ${relativeTimeAgo(moment.createdAt)}'
        : relativeTimeAgo(moment.createdAt);

    return Opacity(
      opacity: dimmed ? 0.82 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dimmed ? 0.15 : 0.35),
              blurRadius: dimmed ? 10 : 24,
              offset: Offset(0, dimmed ? 5 : 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _MomentPhoto(moment: moment, heroEnabled: heroEnabled),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xCC000000),
                    ],
                    stops: [0, 0.22, 0.55, 1],
                  ),
                ),
              ),
              if (!dimmed) ...[
                Positioned(
                  top: 10,
                  left: 10,
                  child: _TimeBadge(time: moment.createdAt),
                ),
                if (onMenu != null)
                  Positioned(
                    top: 4,
                    right: 2,
                    child: GestureDetector(
                      onTap: onMenu,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SettingsType.body(Colors.white).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SettingsType.caption(
                                Colors.white.withValues(alpha: 0.72),
                              ).copyWith(fontSize: 10),
                            ),
                          ),
                          _ReactionPill(summary: reactions),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.time});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          _formatBadge(time),
          style: SettingsType.caption(Colors.white).copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 9,
          ),
        ),
      ),
    );
  }

  String _formatBadge(DateTime createdAt) {
    final now = DateTime.now();
    final local = createdAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final momentDay = DateTime(local.year, local.month, local.day);
    final dayDiff = today.difference(momentDay).inDays;

    if (dayDiff == 0) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
    if (dayDiff == 1) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${local.day} ${months[local.month - 1]}';
  }
}

class _MomentPhoto extends StatelessWidget {
  const _MomentPhoto({required this.moment, this.heroEnabled = false});

  final Moment moment;
  final bool heroEnabled;

  @override
  Widget build(BuildContext context) {
    final image = moment.imageUrl == null
        ? ColoredBox(color: AppColors.photoPlaceholderDark)
        : MomentCachedImage(
            imageUrl: moment.imageUrl!,
            fit: BoxFit.cover,
          );

    if (!heroEnabled) return image;

    return Hero(
      tag: MomentHeroTags.photo(
        moment.id,
        scope: MomentHeroTags.scopeMemories,
      ),
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        final child = flightDirection == HeroFlightDirection.push
            ? (toHeroContext.widget as Hero).child
            : (fromHeroContext.widget as Hero).child;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(
                Tween<double>(begin: 16, end: 24).evaluate(animation),
              ),
              child: child,
            );
          },
        );
      },
      child: Material(
        color: Colors.transparent,
        child: image,
      ),
    );
  }
}
