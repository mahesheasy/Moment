import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_icons.dart';
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
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: SettingsType.caption(mc.textTertiary).copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (subtitle != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.md),
            child: Text(
              subtitle!,
              style: SettingsType.body(mc.textSecondary),
            ),
          ),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: mc.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: mc.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SettingsDivider(),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
      color: context.mc.border,
    );
  }
}

class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    required this.label,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBackground,
    this.value,
    this.destructive = false,
    this.showChevron = true,
    super.key,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;
  final String? value;
  final VoidCallback onTap;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final labelColor = destructive ? mc.error : mc.textPrimary;
    final hasIcon = icon != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: hasIcon || subtitle != null ? 12 : 14,
          ),
          child: Row(
            children: [
              if (hasIcon) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBackground ?? mc.accentSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: iconColor ?? mc.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: subtitle == null
                    ? Text(label, style: SettingsType.title(labelColor))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: SettingsType.title(labelColor).copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: SettingsType.caption(mc.textTertiary),
                          ),
                        ],
                      ),
              ),
              if (value != null) ...[
                Text(value!, style: SettingsType.body(mc.textSecondary)),
                const SizedBox(width: 6),
              ],
              if (showChevron)
                Icon(
                  AppIcons.chevronRight,
                  size: 16,
                  color: destructive ? mc.error : mc.textTertiary,
                ),
            ],
          ),
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
