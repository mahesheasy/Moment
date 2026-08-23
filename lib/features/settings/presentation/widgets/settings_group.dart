import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/widgets/moment_controls.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: SettingsType.caption(mc.accent),
          ),
        ),
        if (subtitle != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.md),
            child: Text(
              subtitle!,
              style: SettingsType.body(mc.textSecondary),
            ),
          ),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: mc.surface,
            borderRadius: AppRadius.xlAll,
            border: Border.all(color: mc.border.withValues(alpha: 0.8)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                    color: mc.border.withValues(alpha: 0.5),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    required this.label,
    required this.onTap,
    this.value,
    this.destructive = false,
    super.key,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final labelColor = destructive ? mc.error : mc.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: SettingsType.title(labelColor)),
            ),
            if (value != null) ...[
              Text(value!, style: SettingsType.body(mc.textSecondary)),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: destructive ? mc.error : mc.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        6,
        AppSpacing.sm,
        6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: SettingsType.title(context.mc.textPrimary),
            ),
          ),
          MomentSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
