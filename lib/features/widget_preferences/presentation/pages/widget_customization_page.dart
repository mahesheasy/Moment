import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/widget_typography_styles.dart';
import 'package:moment/core/widget/android_widget_bridge.dart';
import 'package:moment/core/widget/home_widget_sync_service.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/core/widgets/widget_style_preview.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';
import 'package:moment/core/theme/accent_presets.dart';
import 'package:moment/features/widget_preferences/presentation/cubit/widget_customization_cubit.dart';

class WidgetCustomizationPage extends StatelessWidget {
  const WidgetCustomizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WidgetCustomizationCubit>()..load(),
      child: const _HomeWidgetStudioView(),
    );
  }
}

class _HomeWidgetStudioView extends StatefulWidget {
  const _HomeWidgetStudioView();

  @override
  State<_HomeWidgetStudioView> createState() => _HomeWidgetStudioViewState();
}

class _HomeWidgetStudioViewState extends State<_HomeWidgetStudioView> {
  var _backgroundTint = 0.35;
  var _isPinning = false;

  double _previewSizeFor(WidgetDisplaySize size) => switch (size) {
    WidgetDisplaySize.large => 200,
    WidgetDisplaySize.medium => 160,
    WidgetDisplaySize.small => 120,
  };

  Future<void> _previewOnHomeScreen() async {
    setState(() => _isPinning = true);
    await context.read<WidgetCustomizationCubit>().save();
    if (!mounted) return;
    if (Platform.isAndroid) {
      final pinned = await sl<AndroidWidgetBridge>().requestPinToHomeScreen();
      if (pinned) await sl<HomeWidgetSyncService>().sync();
    }
    if (!mounted) return;
    setState(() => _isPinning = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WidgetCustomizationCubit, WidgetCustomizationState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.savedMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.savedMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == WidgetCustomizationStatus.loading ||
            state.status == WidgetCustomizationStatus.initial) {
          return const MomentScaffold(
            body: SafeArea(child: MomentLoading()),
          );
        }

        if (state.draft == null) {
          return MomentScaffold(
            body: SafeArea(
              child: MomentErrorState(
                message: state.errorMessage ?? 'Could not load widget settings.',
                onAction: () => context.read<WidgetCustomizationCubit>().load(),
              ),
            ),
          );
        }

        final draft = state.draft!;
        final cubit = context.read<WidgetCustomizationCubit>();
        final canCustomize = state.canCustomizeWidget;
        final isSaving = state.status == WidgetCustomizationStatus.saving;
        final previewTitle = _previewTitle(draft, state);
        final accent = _parseColor(draft.accentColor);
        final previewSize = _previewSizeFor(draft.displaySize);
        final themes = state.bundle?.themes ?? WidgetTheme.relationshipThemes;

        return MomentScaffold(
          appBar: MomentAppBar(
            title: 'Home Widget',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                  child: Text(
                    'Customize how your moment appears on the home screen.',
                    style: SettingsType.caption(AppColors.textTertiaryDark),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      _SectionLabel('Preview'),
                      const SizedBox(height: 12),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: WidgetStylePreview(
                            preferences: draft.copyWith(showCaptions: true),
                            headerTitle: previewTitle,
                            relativeTime: 'Just now',
                            studioPreview: true,
                            borderless: true,
                            backgroundTint: _backgroundTint,
                            cornerRadius: 16,
                            previewSize: previewSize,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _SectionLabel('Widget style'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 118,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: themes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final theme = themes[index];
                            return WidgetThemeSwatch(
                              theme: theme,
                              selected: draft.theme == theme,
                              accentColor: draft.accentColor,
                              typography: draft.typography,
                              onTap: canCustomize
                                  ? () => cubit.setTheme(theme)
                                  : () => context.push(AppRoutes.premium),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        draft.theme.concept,
                        style: SettingsType.caption(AppColors.textTertiaryDark),
                      ),
                      const SizedBox(height: 28),
                      _SectionLabel('Size'),
                      const SizedBox(height: 10),
                      Row(
                        children: WidgetDisplaySize.values.map((size) {
                          final isLast = size == WidgetDisplaySize.small;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: isLast ? 0 : 8),
                              child: _SizeChip(
                                label: size.label,
                                hint: size.hint,
                                selected: draft.displaySize == size,
                                onTap: canCustomize
                                    ? () => cubit.setDisplaySize(size)
                                    : () => context.push(AppRoutes.premium),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),
                      _Panel(
                        title: 'Who to show',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SourceRow(
                              label: _sourceLabel(draft, state),
                              onTap: canCustomize
                                  ? () => _pickSource(context, cubit, state)
                                  : () => context.push(AppRoutes.premium),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Keeps the 5 most recent moments. When several friends send moments, tap the left or right edge of the widget to browse them.',
                              style: SettingsType.caption(
                                AppColors.textTertiaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Panel(
                        title: 'Typography',
                        child: Column(
                          children: WidgetTypography.values.map((typography) {
                            final selected = draft.typography == typography;
                            return _TypographyRow(
                              typography: typography,
                              selected: selected,
                              accent: accent,
                              onTap: canCustomize
                                  ? () => cubit.setTypography(typography)
                                  : () => context.push(AppRoutes.premium),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Panel(
                        title: 'Accent color',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: kAccentPresets.map((hex) {
                                final color = _parseColor(hex);
                                final selected =
                                    draft.accentColor.toUpperCase() == hex.toUpperCase();
                                return GestureDetector(
                                  onTap: canCustomize
                                      ? () => cubit.setAccentColor(hex)
                                      : () => context.push(AppRoutes.premium),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color,
                                      border: Border.all(
                                        color: selected
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: selected
                                        ? const Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '#${draft.accentColor.replaceFirst('#', '').toUpperCase()}',
                              style: SettingsType.caption(
                                AppColors.textTertiaryDark,
                              ).copyWith(fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Photo overlay',
                                  style: SettingsType.caption(
                                    AppColors.textTertiaryDark,
                                  ),
                                ),
                                Text(
                                  '${(_backgroundTint * 100).round()}%',
                                  style: SettingsType.body(AppColors.textSecondaryDark),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                                overlayShape: SliderComponentShape.noOverlay,
                              ),
                              child: Slider(
                                value: _backgroundTint,
                                min: 0,
                                max: 0.7,
                                activeColor: AppColors.violet,
                                inactiveColor: AppColors.borderDark,
                                onChanged: canCustomize
                                    ? (v) => setState(() => _backgroundTint = v)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _StudioFooter(
                  isSaving: isSaving,
                  isPinning: _isPinning,
                  canCustomize: canCustomize,
                  onPreview: _previewOnHomeScreen,
                  onSave: canCustomize
                      ? cubit.save
                      : () => context.push(AppRoutes.premium),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String hex) {
    final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | value);
  }

  String _previewTitle(
    WidgetPreferences draft,
    WidgetCustomizationState state,
  ) {
    return _sourceLabel(draft, state);
  }

  String _sourceLabel(
    WidgetPreferences draft,
    WidgetCustomizationState state,
  ) {
    return switch (draft.widgetMode) {
      WidgetMode.circle =>
        state.circles
            .where((c) => c.id == draft.selectedCircleId)
            .map((c) => c.name)
            .firstOrNull ??
        'Circle',
      WidgetMode.person =>
        state.friends
            .where((f) => f.profile.id == draft.selectedPersonId)
            .map((f) => f.profile.displayName)
            .firstOrNull ??
        'One person',
      WidgetMode.latest => 'Latest from friends',
    };
  }

  Future<void> _pickSource(
    BuildContext context,
    WidgetCustomizationCubit cubit,
    WidgetCustomizationState state,
  ) async {
    final changed = await MomentBottomSheet.show<bool>(
      context,
      title: 'Who to show',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: ListView(
          shrinkWrap: true,
          children: [
            _SheetChoice(
              label: 'Latest from friends',
              subtitle: 'Newest moment from anyone',
              selected: state.draft?.widgetMode == WidgetMode.latest,
              onTap: () {
                cubit.setWidgetMode(WidgetMode.latest);
                Navigator.of(context).pop(true);
              },
            ),
            ...state.friends.map(
              (friend) => _SheetChoice(
                label: friend.profile.displayName,
                subtitle: 'Only moments from this person',
                selected:
                    state.draft?.widgetMode == WidgetMode.person &&
                    state.draft?.selectedPersonId == friend.profile.id,
                leading: MomentAvatar(
                  name: friend.profile.displayName,
                  imageUrl: friend.profile.avatarUrl,
                  size: 28,
                ),
                onTap: () {
                  cubit.setWidgetMode(WidgetMode.person);
                  cubit.setSelectedPerson(friend.profile.id);
                  Navigator.of(context).pop(true);
                },
              ),
            ),
            if (state.circles.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 6),
                child: Text(
                  'Circles',
                  style: SettingsType.caption(AppColors.textTertiaryDark),
                ),
              ),
              ...state.circles.map(
                (circle) => _SheetChoice(
                  label: circle.name,
                  subtitle: 'Latest from circle members',
                  selected:
                      state.draft?.widgetMode == WidgetMode.circle &&
                      state.draft?.selectedCircleId == circle.id,
                  onTap: () {
                    cubit.setWidgetMode(WidgetMode.circle);
                    cubit.setSelectedCircle(circle.id);
                    Navigator.of(context).pop(true);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (changed == true) await cubit.save();
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevatedDark,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: SettingsType.title(AppColors.textPrimaryDark),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiaryDark,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetChoice extends StatelessWidget {
  const _SheetChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: leading,
      title: Text(
        label,
        style: SettingsType.title(
          selected ? AppColors.violet : AppColors.textPrimaryDark,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: SettingsType.caption(AppColors.textTertiaryDark),
            ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: AppColors.violet, size: 18)
          : null,
      onTap: onTap,
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
      style: SettingsType.title(AppColors.textSecondaryDark).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: SettingsType.title(AppColors.textPrimaryDark).copyWith(
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TypographyRow extends StatelessWidget {
  const _TypographyRow({
    required this.typography,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final WidgetTypography typography;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.violet.withValues(alpha: 0.06)
                  : AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.violet : AppColors.borderDark,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      'Aa',
                      style: WidgetTypographyStyles.sample(typography, accent),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typography.label,
                          style: SettingsType.title(
                            selected
                                ? AppColors.textPrimaryDark
                                : AppColors.textSecondaryDark,
                          ),
                        ),
                        Text(
                          typography.subtitle,
                          style: SettingsType.caption(AppColors.textTertiaryDark),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_rounded, size: 18, color: AppColors.violet),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.violet : AppColors.borderDark,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: SettingsType.title(
                selected ? AppColors.textPrimaryDark : AppColors.textSecondaryDark,
              ).copyWith(fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(hint, style: SettingsType.caption(AppColors.textTertiaryDark)),
          ],
        ),
      ),
    );
  }
}

class _StudioFooter extends StatelessWidget {
  const _StudioFooter({
    required this.isSaving,
    required this.isPinning,
    required this.canCustomize,
    required this.onPreview,
    required this.onSave,
  });

  final bool isSaving;
  final bool isPinning;
  final bool canCustomize;
  final VoidCallback onPreview;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          top: BorderSide(color: AppColors.borderDark.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: isPinning ? null : onPreview,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimaryDark,
                side: BorderSide(color: AppColors.borderDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isPinning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Preview on Home Screen'),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: isSaving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.violet,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      canCustomize ? 'Save Widget' : 'Unlock with Moment+',
                      style: SettingsType.title(Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
