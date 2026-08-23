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
import 'package:moment/core/widget/android_widget_bridge.dart';
import 'package:moment/core/widget/home_widget_sync_service.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/core/widgets/widget_style_preview.dart';
import 'package:moment/features/settings/presentation/widgets/settings_group.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';
import 'package:moment/features/widget_preferences/presentation/cubit/widget_customization_cubit.dart';

const _lookThemes = [
  WidgetTheme.minimal,
  WidgetTheme.glass,
  WidgetTheme.film,
  WidgetTheme.sunset,
];

class WidgetSettingsPage extends StatelessWidget {
  const WidgetSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WidgetCustomizationCubit>()..load(),
      child: const _WidgetSettingsView(),
    );
  }
}

class _WidgetSettingsView extends StatefulWidget {
  const _WidgetSettingsView();

  @override
  State<_WidgetSettingsView> createState() => _WidgetSettingsViewState();
}

class _WidgetSettingsViewState extends State<_WidgetSettingsView> {
  var _isPinning = false;

  Future<void> _previewOnHomeScreen() async {
    setState(() => _isPinning = true);
    final cubit = context.read<WidgetCustomizationCubit>();
    await cubit.save();
    if (!mounted) return;

    if (Platform.isAndroid) {
      final pinned = await sl<AndroidWidgetBridge>().requestPinToHomeScreen();
      if (pinned) await sl<HomeWidgetSyncService>().sync();
      if (!mounted) return;
      setState(() => _isPinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pinned
                ? 'Confirm adding Moment on your home screen.'
                : 'Long-press your home screen, choose Widgets, then add Moment.',
          ),
        ),
      );
      return;
    }

    setState(() => _isPinning = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add the Moment widget from your home screen widgets menu.'),
      ),
    );
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
            appBar: MomentAppBar(title: 'Widget'),
            body: MomentLoading(),
          );
        }

        if (state.draft == null) {
          return MomentScaffold(
            appBar: const MomentAppBar(title: 'Widget'),
            body: MomentErrorState(
              message: state.errorMessage ?? 'Could not load widget settings.',
              onAction: () => context.read<WidgetCustomizationCubit>().load(),
            ),
          );
        }

        final draft = state.draft!;
        final cubit = context.read<WidgetCustomizationCubit>();
        final person = _personLabel(draft, state);
        final previewTitle = person == 'Latest' ? 'Jay' : person;

        return MomentScaffold(
          appBar: MomentAppBar(
            title: 'Widget',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              onPressed: () => context.pop(),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: FilledButton(
                onPressed: _isPinning ? null : _previewOnHomeScreen,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isPinning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Preview on Home Screen'),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Text(
                'Customize how your moments appear',
                style: SettingsType.body(AppColors.textSecondaryDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                child: WidgetStylePreview(
                  preferences: draft,
                  headerTitle: previewTitle,
                  borderless: true,
                  previewSize: 220,
                ),
              ),
              const SizedBox(height: 32),
              SettingsSection(
                title: 'Privacy',
                children: [
                  SettingsNavRow(
                    label: 'Mode',
                    value: draft.privacyMode.label,
                    onTap: () => _pickPrivacyMode(context, cubit, draft),
                  ),
                  SettingsToggleRow(
                    label: 'Lock screen',
                    value: draft.lockScreenPrivacy,
                    onChanged: (value) {
                      cubit.setLockScreenPrivacy(value);
                      unawaited(cubit.savePrivacy(silent: true));
                    },
                  ),
                  SettingsToggleRow(
                    label: 'Pause updates',
                    value: draft.paused,
                    onChanged: (value) {
                      cubit.setPaused(value);
                      unawaited(cubit.savePrivacy(silent: true));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: 'Shown',
                children: [
                  SettingsNavRow(
                    label: 'Person',
                    value: person,
                    onTap: () => _pickSource(context, cubit, state),
                  ),
                  SettingsToggleRow(
                    label: 'Sender',
                    value: draft.showSender,
                    onChanged: (value) {
                      cubit.setShowSender(value);
                      unawaited(cubit.savePrivacy(silent: true));
                    },
                  ),
                  SettingsToggleRow(
                    label: 'Timestamp',
                    value: draft.showTimestamp,
                    onChanged: (value) {
                      cubit.setShowTimestamp(value);
                      unawaited(cubit.savePrivacy(silent: true));
                    },
                  ),
                  SettingsToggleRow(
                    label: 'Captions',
                    value: draft.showCaptions,
                    onChanged: (value) {
                      cubit.setShowCaptions(value);
                      unawaited(cubit.savePrivacy(silent: true));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: 'Look',
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      14,
                      AppSpacing.lg,
                      14,
                    ),
                    child: SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _lookThemes.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final theme = _lookThemes[index];
                          final selected = draft.theme == theme;
                          return WidgetThemeSwatch(
                            theme: theme,
                            selected: selected,
                            accentColor: draft.accentColor,
                            typography: draft.typography,
                            onTap: state.canCustomizeWidget
                                ? () {
                                    cubit.setTheme(theme);
                                    unawaited(cubit.save());
                                  }
                                : () => context.push(AppRoutes.premium),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _personLabel(
    WidgetPreferences draft,
    WidgetCustomizationState state,
  ) {
    return switch (draft.widgetMode) {
      WidgetMode.person =>
        state.friends
            .where((f) => f.profile.id == draft.selectedPersonId)
            .map((f) => f.profile.displayName)
            .firstOrNull ??
        'Choose',
      WidgetMode.circle =>
        state.circles
            .where((c) => c.id == draft.selectedCircleId)
            .map((c) => c.name)
            .firstOrNull ??
        'Circle',
      WidgetMode.latest => 'Latest',
    };
  }

  Future<void> _pickPrivacyMode(
    BuildContext context,
    WidgetCustomizationCubit cubit,
    WidgetPreferences draft,
  ) async {
    final changed = await MomentBottomSheet.show<bool>(
      context,
      title: 'Privacy mode',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: WidgetPrivacyMode.values
            .map(
              (mode) => _SheetChoice(
                label: mode.label,
                subtitle: mode.description,
                selected: draft.privacyMode == mode,
                onTap: () {
                  cubit.setPrivacyMode(mode);
                  Navigator.of(context).pop(true);
                },
              ),
            )
            .toList(),
      ),
    );
    if (changed == true) await cubit.savePrivacy(silent: true);
  }

  Future<void> _pickSource(
    BuildContext context,
    WidgetCustomizationCubit cubit,
    WidgetCustomizationState state,
  ) async {
    if (!state.canCustomizeWidget) {
      unawaited(context.push(AppRoutes.premium));
      return;
    }

    final changed = await MomentBottomSheet.show<bool>(
      context,
      title: 'Person',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: ListView(
          shrinkWrap: true,
          children: [
            _SheetChoice(
              label: 'Latest',
              selected: state.draft?.widgetMode == WidgetMode.latest,
              onTap: () {
                cubit.setWidgetMode(WidgetMode.latest);
                Navigator.of(context).pop(true);
              },
            ),
            ...state.friends.map(
              (friend) => _SheetChoice(
                label: friend.profile.displayName,
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
          ? Icon(Icons.check_rounded, size: 18, color: AppColors.violet)
          : null,
      onTap: onTap,
    );
  }
}
