import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_component_sizes.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/moment_theme.dart';

class DarkPageTitle extends StatelessWidget {
  const DarkPageTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: context.mc.accent,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

class DarkPillTabs extends StatelessWidget {
  const DarkPillTabs({
    required this.left,
    required this.right,
    required this.leftSelected,
    required this.onLeft,
    required this.onRight,
    this.rightBadge,
    this.expanded = false,
    super.key,
  });

  final String left;
  final String right;
  final bool leftSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final int? rightBadge;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    if (!expanded) {
      return Row(
        children: [
          _Tab(label: left, selected: leftSelected, onTap: onLeft),
          const SizedBox(width: AppSpacing.md),
          _Tab(
            label: right,
            selected: !leftSelected,
            onTap: onRight,
            badge: rightBadge,
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: mc.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: left,
              selected: leftSelected,
              onTap: onLeft,
              fill: true,
            ),
          ),
          Expanded(
            child: _Tab(
              label: right,
              selected: !leftSelected,
              onTap: onRight,
              badge: rightBadge,
              fill: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.fill = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: fill ? double.infinity : null,
        alignment: fill ? Alignment.center : null,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? mc.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(fill ? 14 : 22),
        ),
        child: Row(
          mainAxisSize: fill ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? mc.textPrimary : mc.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (badge != null && badge! > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$badge',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: mc.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DarkSearchField extends StatelessWidget {
  const DarkSearchField({
    required this.hint,
    required this.onChanged,
    this.controller,
    super.key,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: mc.textPrimary),
      cursorColor: mc.accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: mc.textTertiary),
        prefixIcon: Icon(AppIcons.search, color: mc.textTertiary),
        filled: true,
        fillColor: mc.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class DarkPrimaryButton extends StatelessWidget {
  const DarkPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return SizedBox(
      width: double.infinity,
      height: AppComponentSizes.buttonHeightLg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: mc.bloomGradient,
          boxShadow: [
            BoxShadow(
              color: mc.accent.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
