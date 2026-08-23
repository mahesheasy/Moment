import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/dark_page_chrome.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/features/memories/domain/entities/memory_theme.dart';

class MemoryFormPanel extends StatelessWidget {
  const MemoryFormPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: child,
    );
  }
}

class MemoryFormSection extends StatelessWidget {
  const MemoryFormSection({
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DarkPageTitle(title),
        if (subtitle != null) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiaryDark),
          ),
        ],
        SizedBox(height: AppSpacing.lg),
        child,
      ],
    );
  }
}

class MemoryFormField extends StatelessWidget {
  const MemoryFormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiaryDark,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          cursorColor: AppColors.violet,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiaryDark),
            filled: true,
            fillColor: AppColors.surfaceElevatedDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.violet, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }
}

class MemoryFormChip extends StatelessWidget {
  const MemoryFormChip({
    required this.label,
    required this.selected,
    this.onTap,
    this.locked = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !locked;

    return Material(
      color: selected
          ? AppColors.violet.withValues(alpha: 0.16)
          : AppColors.surfaceElevatedDark,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.violet
                  : locked
                  ? AppColors.borderDark.withValues(alpha: 0.6)
                  : AppColors.borderDark,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? AppColors.violet
                      : locked
                      ? AppColors.textTertiaryDark
                      : AppColors.textSecondaryDark,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              if (locked) ...[
                SizedBox(width: 4),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: AppColors.textTertiaryDark.withValues(alpha: 0.8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MemoryFormDateRow extends StatelessWidget {
  const MemoryFormDateRow({required this.date, required this.onTap, super.key});

  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = date == null ? 'Not set' : _formatDate(date!);

    return Material(
      color: AppColors.surfaceElevatedDark,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DATE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiaryDark,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: date == null
                            ? AppColors.textTertiaryDark
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.violet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class MemoryFormCircleTile extends StatelessWidget {
  const MemoryFormCircleTile({
    required this.emoji,
    required this.name,
    required this.selected,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final String emoji;
  final String name;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.violet.withValues(alpha: 0.12)
          : AppColors.surfaceElevatedDark,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.violet : AppColors.borderDark,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiaryDark,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: selected ? AppColors.violet : AppColors.textTertiaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemoryThemePicker extends StatelessWidget {
  const MemoryThemePicker({
    required this.themes,
    required this.selected,
    required this.isPremium,
    required this.onSelected,
    super.key,
  });

  final List<MemoryTheme> themes;
  final MemoryTheme selected;
  final bool isPremium;
  final ValueChanged<MemoryTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: themes.map((theme) {
        final locked = theme != MemoryTheme.minimal && !isPremium;
        return MemoryFormChip(
          label: theme.label,
          selected: selected == theme,
          locked: locked,
          onTap: locked ? null : () => onSelected(theme),
        );
      }).toList(),
    );
  }
}

class MemoryFormStickyBar extends StatelessWidget {
  const MemoryFormStickyBar({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.md,
            AppSpacing.xxl,
            AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withValues(alpha: 0.92),
            border: Border(top: BorderSide(color: AppColors.borderDark)),
          ),
          child: MomentButton(
            label: label,
            isLoading: isLoading,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

class MemoryFormSheetHeader extends StatelessWidget {
  const MemoryFormSheetHeader({
    required this.title,
    this.subtitle,
    this.onClose,
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.borderDark,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onClose != null)
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, size: 22),
                color: AppColors.textSecondaryDark,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevatedDark,
                  padding: const EdgeInsets.all(8),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
