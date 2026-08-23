import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/accent_presets.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/features/settings/data/datasources/appearance_preferences_local_cache.dart';
import 'package:moment/features/settings/presentation/cubit/appearance_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_group.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppearanceSettingsView();
  }
}

class _AppearanceSettingsView extends StatelessWidget {
  const _AppearanceSettingsView();

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;

    return BlocBuilder<AppearanceCubit, AppearanceState>(
      builder: (context, state) {
        final cubit = sl<AppearanceCubit>();
        final prefs = state.preferences;

        return MomentScaffold(
          appBar: MomentAppBar(
            title: 'Appearance',
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(AppIcons.back, size: 18),
              onPressed: () => context.pop(),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.huge,
            ),
            children: [
              Text(
                'Make it yours',
                style: SettingsType.title(mc.textPrimary)
                    .copyWith(fontSize: 17, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Theme and accent apply across the app, including premium.',
                style: SettingsType.caption(mc.textTertiary)
                    .copyWith(fontWeight: FontWeight.w400, fontSize: 11),
              ),
              const SizedBox(height: AppSpacing.xl),
              SettingsSection(
                title: 'Theme',
                subtitle: 'Light, dark, or follow your device',
                children: [
                  _ThemeModeRow(
                    label: 'System',
                    selected: prefs.theme == AppThemePreference.system,
                    onTap: () => cubit.setTheme(AppThemePreference.system),
                  ),
                  _ThemeModeRow(
                    label: 'Light',
                    selected: prefs.theme == AppThemePreference.light,
                    onTap: () => cubit.setTheme(AppThemePreference.light),
                  ),
                  _ThemeModeRow(
                    label: 'Dark',
                    selected: prefs.theme == AppThemePreference.dark,
                    onTap: () => cubit.setTheme(AppThemePreference.dark),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              SettingsSection(
                title: 'Accent color',
                subtitle: 'Pink accent for premium and highlights',
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final hex in kAccentPresets)
                          _AccentSwatch(
                            hex: hex,
                            selected: prefs.accentHex.toUpperCase() ==
                                hex.toUpperCase(),
                            onTap: () => cubit.setAccentHex(hex),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: mc.bloomGradient,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Preview',
                          style: SettingsType.title(Colors.white)
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Premium',
                          style: SettingsType.caption(Colors.white)
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
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
              child: Text(
                label,
                style: SettingsType.title(mc.textPrimary),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? mc.accent : mc.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = accentFromHex(hex);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Accent $hex',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? context.mc.textPrimary : Colors.transparent,
              width: 2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}
