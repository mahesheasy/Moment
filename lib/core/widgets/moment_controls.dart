import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_component_sizes.dart';

/// Compact switch used across settings and privacy screens.
class MomentSwitch extends StatelessWidget {
  const MomentSwitch({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Transform.scale(
      scale: AppComponentSizes.switchScale,
      alignment: Alignment.centerRight,
      child: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        activeThumbColor: Colors.white,
        activeTrackColor: isDark ? AppColors.violet : AppColors.accent,
        inactiveThumbColor: isDark ? AppColors.textTertiaryDark : Colors.white,
        inactiveTrackColor: isDark
            ? AppColors.surfaceElevatedDark
            : AppColors.border,
      ),
    );
  }
}

/// Compact radio indicator for selection rows.
class MomentRadioIndicator extends StatelessWidget {
  const MomentRadioIndicator({
    required this.selected,
    super.key,
    this.activeColor,
  });

  final bool selected;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.violet;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: AppComponentSizes.radioOuter,
      height: AppComponentSizes.radioOuter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? color : AppColors.borderDark,
          width: selected
              ? AppComponentSizes.radioBorderSelected
              : AppComponentSizes.radioBorderUnselected,
        ),
      ),
    );
  }
}

/// Compact radio row — alternative to Material [RadioListTile].
class MomentRadioRow<T> extends StatelessWidget {
  const MomentRadioRow({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    super.key,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            MomentRadioIndicator(selected: selected),
          ],
        ),
      ),
    );
  }
}
