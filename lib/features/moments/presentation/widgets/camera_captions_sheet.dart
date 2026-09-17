import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/features/moments/domain/moment_decorations.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';

Future<void> showCameraCaptionsSheet(
  BuildContext context, {
  required TextEditingController reviewController,
}) {
  final cubit = context.read<CameraCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: const Color(0xFF1C1C1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return BlocProvider.value(
        value: cubit,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _CaptionsSheet(reviewController: reviewController),
        ),
      );
    },
  );
}

class _CaptionsSheet extends StatelessWidget {
  const _CaptionsSheet({required this.reviewController});

  final TextEditingController reviewController;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CameraCubit>().state;
    final cubit = context.read<CameraCubit>();
    final loading = state.isLoadingContext;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Add to moment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('GENERAL'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GeneralChip(
                label: 'Location',
                icon: Icons.location_on_outlined,
                selected: state.includeLocation,
                enabled: !loading && state.locationLabel != null,
                onTap: cubit.toggleIncludeLocation,
                valueLabel: loading
                    ? 'Loading…'
                    : state.locationLabel,
              ),
              _GeneralChip(
                label: 'Weather',
                icon: Icons.cloud_outlined,
                selected: state.includeWeather,
                enabled: !loading && state.weatherLabel != null,
                onTap: cubit.toggleIncludeWeather,
                valueLabel: loading
                    ? 'Loading…'
                    : state.weatherLabel,
              ),
              if (state.timeLabel != null)
                _GeneralChip(
                  label: state.timeLabel!,
                  icon: Icons.schedule_outlined,
                  selected: state.includeTime,
                  onTap: cubit.toggleIncludeTime,
                ),
              if (state.streakCount > 0)
                _GeneralChip(
                  label: '${state.streakCount}',
                  leading: '🔥',
                  selected: state.includeStreak,
                  accent: true,
                  onTap: cubit.toggleIncludeStreak,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Review',
            style: TextStyle(
              color: AppColors.textTertiaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => cubit.setReviewRating(i),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      i <= state.reviewRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFFFB020),
                      size: 32,
                    ),
                  ),
                ),
              if (state.reviewRating > 0)
                TextButton(
                  onPressed: () => cubit.setReviewRating(0),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: AppColors.textTertiaryDark,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: reviewController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: AppColors.violet,
            decoration: InputDecoration(
              hintText: 'Write a review…',
              hintStyle: TextStyle(color: AppColors.textTertiaryDark),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: cubit.setReviewText,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('DECORATIVE'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in MomentDecorations.decorative)
                _DecorativeChip(
                  tag: tag,
                  selected: state.decorations.contains(tag),
                  onTap: () => cubit.toggleDecoration(tag),
                ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textTertiaryDark,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _GeneralChip extends StatelessWidget {
  const _GeneralChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconColor,
    this.leading,
    this.enabled = true,
    this.accent = false,
    this.valueLabel,
  });

  final String label;
  final String? valueLabel;
  final IconData? icon;
  final Color? iconColor;
  final String? leading;
  final bool selected;
  final bool enabled;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = accent
        ? const Color(0xFFFFD54F)
        : selected
        ? AppColors.violet.withValues(alpha: 0.2)
        : const Color(0xFF2C2C2E);
    final fg = accent
        ? const Color(0xFF3D2800)
        : selected
        ? Colors.white
        : AppColors.textSecondaryDark;

    final display = _chipDisplayLabel();

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: selected && !accent
                ? Border.all(color: AppColors.violet.withValues(alpha: 0.45))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Text(leading!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
              ],
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor ?? fg),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _chipDisplayLabel() {
    if (valueLabel != null &&
        valueLabel!.isNotEmpty &&
        valueLabel != 'Loading…') {
      return valueLabel!;
    }
    if (valueLabel == 'Loading…') return valueLabel!;
    return label;
  }
}

class _DecorativeChip extends StatelessWidget {
  const _DecorativeChip({
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
      child: Opacity(
        opacity: selected ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: style.background,
            gradient: style.gradient,
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5)
                : null,
          ),
          child: Text(
            '${MomentDecorations.emojiFor(tag)} ${MomentDecorations.displayLabel(tag)}',
            style: TextStyle(
              color: style.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
