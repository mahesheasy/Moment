import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/features/moments/domain/moment_decorations.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/widgets/moment_detail_arc.dart';

/// Compact action panel shown below the arc for the currently selected item.
class MomentDetailArcPanel extends StatelessWidget {
  const MomentDetailArcPanel({
    required this.selectedType,
    required this.reviewController,
    super.key,
  });

  final MomentDetailType selectedType;
  final TextEditingController reviewController;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey(selectedType),
        child: _PanelBody(
          selectedType: selectedType,
          reviewController: reviewController,
        ),
      ),
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({
    required this.selectedType,
    required this.reviewController,
  });

  final MomentDetailType selectedType;
  final TextEditingController reviewController;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CameraCubit>().state;
    final cubit = context.read<CameraCubit>();
    final loading = state.isLoadingContext;

    return SizedBox(
      height: 56,
      child: switch (selectedType) {
        MomentDetailType.location => _CapsuleToggle(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: loading ? 'Loading…' : state.locationLabel ?? 'Unavailable',
          selected: state.includeLocation,
          enabled: !loading && state.locationLabel != null,
          onTap: cubit.toggleIncludeLocation,
        ),
        MomentDetailType.weather => _CapsuleToggle(
          icon: Icons.cloud_outlined,
          label: 'Weather',
          value: loading ? 'Loading…' : state.weatherLabel ?? 'Unavailable',
          selected: state.includeWeather,
          enabled: !loading && state.weatherLabel != null,
          onTap: cubit.toggleIncludeWeather,
        ),
        MomentDetailType.stickers => _StickersRow(
          decorations: state.decorations,
          onToggle: cubit.toggleDecoration,
        ),
        MomentDetailType.review => _ReviewRow(
          rating: state.reviewRating,
          reviewController: reviewController,
          onRating: cubit.setReviewRating,
          onText: cubit.setReviewText,
        ),
        MomentDetailType.time => _CapsuleToggle(
          icon: Icons.schedule_outlined,
          label: 'Time',
          value: state.timeLabel ?? 'Unavailable',
          selected: state.includeTime,
          enabled: state.timeLabel != null,
          onTap: cubit.toggleIncludeTime,
        ),
      },
    );
  }
}

/// Tablet-style capsule row for add/remove toggles (location, weather, time).
class _CapsuleToggle extends StatelessWidget {
  const _CapsuleToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF16161A),
      shape: const StadiumBorder(side: BorderSide(color: Color(0x1FFFFFFF))),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const StadiumBorder(),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.violet.withValues(alpha: 0.16)
                        : const Color(0xFF222226),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? AppColors.violet : Colors.white70,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textTertiaryDark,
                          fontSize: 11,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.violet.withValues(alpha: 0.6)
                          : AppColors.textTertiaryDark.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    selected ? Icons.check_rounded : Icons.add_rounded,
                    size: 16,
                    color: selected
                        ? AppColors.violet
                        : AppColors.textTertiaryDark,
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

class _StickersRow extends StatelessWidget {
  const _StickersRow({required this.decorations, required this.onToggle});

  final Set<String> decorations;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tag in MomentDecorations.decorative)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _StickerCapsule(
                  tag: tag,
                  selected: decorations.contains(tag),
                  onTap: () => onToggle(tag),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StickerCapsule extends StatelessWidget {
  const _StickerCapsule({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final String tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = MomentDecorations.pillStyle(tag);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: style.background,
          gradient: style.gradient,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              MomentDecorations.emojiFor(tag),
              style: const TextStyle(fontSize: 14, height: 1),
            ),
            const SizedBox(width: 5),
            Text(
              MomentDecorations.displayLabel(tag),
              style: TextStyle(
                color: style.textColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.rating,
    required this.reviewController,
    required this.onRating,
    required this.onText,
  });

  final int rating;
  final TextEditingController reviewController;
  final ValueChanged<int> onRating;
  final ValueChanged<String> onText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF16161A),
      shape: const StadiumBorder(side: BorderSide(color: Color(0x1FFFFFFF))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (var i = 1; i <= 5; i++)
              GestureDetector(
                onTap: () => onRating(i),
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    i <= rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFB020),
                    size: 24,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: reviewController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                cursorColor: AppColors.violet,
                decoration: InputDecoration(
                  hintText: 'Rate this moment…',
                  hintStyle: TextStyle(
                    color: AppColors.textTertiaryDark,
                    fontSize: 11,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: onText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
