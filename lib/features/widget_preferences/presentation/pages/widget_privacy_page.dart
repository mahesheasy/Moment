import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_component_sizes.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_controls.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/core/widgets/widget_style_preview.dart';
import 'package:moment/features/settings/presentation/widgets/settings_group.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';
import 'package:moment/features/widget_preferences/presentation/cubit/widget_customization_cubit.dart';
import 'package:moment/core/theme/app_colors.dart';

class WidgetPrivacyPage extends StatelessWidget {
  const WidgetPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WidgetCustomizationCubit>()..load(),
      child: const _WidgetPrivacyView(),
    );
  }
}

class _WidgetPrivacyView extends StatelessWidget {
  const _WidgetPrivacyView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WidgetCustomizationCubit, WidgetCustomizationState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        if (state.status == WidgetCustomizationStatus.loading ||
            state.status == WidgetCustomizationStatus.initial) {
          return const MomentScaffold(
            appBar: MomentAppBar(title: 'Widget Privacy'),
            body: MomentLoading(),
          );
        }

        if (state.draft == null) {
          return MomentScaffold(
            appBar: const MomentAppBar(title: 'Widget Privacy'),
            body: MomentErrorState(
              message: state.errorMessage ?? 'Could not load widget privacy.',
              onAction: () => context.read<WidgetCustomizationCubit>().load(),
            ),
          );
        }

        final draft = state.draft!;
        final cubit = context.read<WidgetCustomizationCubit>();
        final previewPerson = _previewPerson(draft, state);

        return MomentScaffold(
          appBar: MomentAppBar(
            title: 'Widget Privacy',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              onPressed: () => context.pop(),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                'How moments appear',
                style: SettingsType.title(AppColors.textPrimaryDark).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Privacy controls how a moment looks — not which moment is selected.',
                style: SettingsType.body(AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 20),
              Center(
                child: WidgetStylePreview(
                  preferences: draft,
                  stackMoments: state.previewStackMoments.isEmpty
                      ? null
                      : state.previewStackMoments,
                  headerTitle: previewPerson.name,
                  relativeTime: state.previewStackMoments.isNotEmpty
                      ? state.previewStackMoments.first.relativeTime
                      : 'Just now',
                  forcePrivacyMode: draft.privacyForSender(previewPerson.id),
                  previewSize: 200,
                  streakCount: state.previewStreakCount,
                ),
              ),
              const SizedBox(height: 28),
              SettingsSection(
                title: 'Privacy',
                children: [
                  for (final mode in WidgetPrivacyMode.values)
                    _PrivacyRow(
                      mode: mode,
                      selected: draft.privacyMode == mode,
                      onTap: () => cubit.setPrivacyMode(mode),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: 'For specific people',
                children: [
                  if (state.friends.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 12,
                      ),
                      child: Text(
                        'Add friends to set privacy per person.',
                        style: SettingsType.body(AppColors.textSecondaryDark),
                      ),
                    )
                  else
                    ...state.friends.map(
                      (friend) => _OverrideRow(
                        name: friend.profile.displayName,
                        avatarUrl: friend.profile.avatarUrl,
                        effectiveMode: draft.privacyForSender(friend.profile.id),
                        hasOverride:
                            draft.privacyOverrides.containsKey(friend.profile.id),
                        onTap: () => _showOverridePicker(
                          context,
                          cubit: cubit,
                          senderId: friend.profile.id,
                          senderName: friend.profile.displayName,
                          draft: draft,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: 'Lock screen',
                children: [
                  SettingsToggleRow(
                    label: 'Hide widget content when locked',
                    value: draft.lockScreenPrivacy,
                    onChanged: cubit.setLockScreenPrivacy,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: 'Display',
                children: [
                  SettingsToggleRow(
                    label: 'Show sender',
                    value: draft.showSender,
                    onChanged: cubit.setShowSender,
                  ),
                  SettingsToggleRow(
                    label: 'Show timestamp',
                    value: draft.showTimestamp,
                    onChanged: cubit.setShowTimestamp,
                  ),
                  SettingsToggleRow(
                    label: 'Show captions',
                    value: draft.showCaptions,
                    onChanged: cubit.setShowCaptions,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: 'Updates',
                children: [
                  SettingsToggleRow(
                    label: 'Pause updates',
                    value: draft.paused,
                    onChanged: cubit.setPaused,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  ({String id, String name}) _previewPerson(
    WidgetPreferences draft,
    WidgetCustomizationState state,
  ) {
    if (draft.privacyOverrides.isNotEmpty) {
      final senderId = draft.privacyOverrides.keys.first;
      final friend = state.friends
          .where((f) => f.profile.id == senderId)
          .map((f) => f.profile.displayName)
          .firstOrNull;
      return (id: senderId, name: friend ?? 'Friend');
    }
    if (draft.privacyPersonId != null) {
      final friend = state.friends
          .where((f) => f.profile.id == draft.privacyPersonId)
          .map((f) => f.profile.displayName)
          .firstOrNull;
      return (id: draft.privacyPersonId!, name: friend ?? 'Friend');
    }
    final firstFriend = state.friends.firstOrNull;
    if (firstFriend != null) {
      return (
        id: firstFriend.profile.id,
        name: firstFriend.profile.displayName,
      );
    }
    return (id: 'preview-sender', name: 'Jay');
  }

  void _showOverridePicker(
    BuildContext context, {
    required WidgetCustomizationCubit cubit,
    required String senderId,
    required String senderName,
    required WidgetPreferences draft,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        final override = draft.privacyOverrides[senderId];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              0,
              AppSpacing.sm,
              0,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        senderName,
                        textAlign: TextAlign.center,
                        style: SettingsType.title(AppColors.textPrimaryDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose how ${senderName.split(' ').first}\'s moments appear on your widget.',
                        textAlign: TextAlign.center,
                        style: SettingsType.body(AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _PrivacyPickerRow(
                  label: 'Default',
                  subtitle: 'Use global privacy (${draft.privacyMode.label})',
                  selected: override == null,
                  onTap: () {
                    cubit.setPrivacyOverride(senderId, null);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                _PrivacyPickerRow(
                  label: 'Full',
                  subtitle: 'Show clearly',
                  selected: override == WidgetPrivacyMode.full,
                  onTap: () {
                    cubit.setPrivacyOverride(senderId, WidgetPrivacyMode.full);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                _PrivacyPickerRow(
                  label: 'Blur',
                  subtitle: 'Show blurred',
                  selected: override == WidgetPrivacyMode.blur,
                  onTap: () {
                    cubit.setPrivacyOverride(senderId, WidgetPrivacyMode.blur);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                _PrivacyPickerRow(
                  label: 'Private',
                  subtitle: 'Hide photo',
                  selected: override == WidgetPrivacyMode.private,
                  onTap: () {
                    cubit.setPrivacyOverride(
                      senderId,
                      WidgetPrivacyMode.private,
                    );
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final WidgetPrivacyMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PrivacyPickerRow(
      label: mode.label,
      subtitle: _modeSubtitle(mode),
      badge: mode == WidgetPrivacyMode.blur ? 'Recommended' : null,
      selected: selected,
      onTap: onTap,
    );
  }

  String _modeSubtitle(WidgetPrivacyMode mode) => switch (mode) {
    WidgetPrivacyMode.full => 'Show moments clearly',
    WidgetPrivacyMode.blur => 'Keep moments subtle',
    WidgetPrivacyMode.private => 'Hide moment photos',
  };
}

class _PrivacyPickerRow extends StatelessWidget {
  const _PrivacyPickerRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final String label;
  final String? subtitle;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: SettingsType.title(AppColors.textPrimaryDark),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          badge!,
                          style: SettingsType.caption(AppColors.violet),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: SettingsType.body(AppColors.textSecondaryDark),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            MomentRadioIndicator(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _OverrideRow extends StatelessWidget {
  const _OverrideRow({
    required this.name,
    required this.effectiveMode,
    required this.hasOverride,
    required this.onTap,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;
  final WidgetPrivacyMode effectiveMode;
  final bool hasOverride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final valueLabel = hasOverride
        ? effectiveMode.label
        : 'Default';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 12,
        ),
        child: Row(
          children: [
            MomentAvatar(name: name, imageUrl: avatarUrl, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: SettingsType.title(AppColors.textPrimaryDark),
              ),
            ),
            Text(
              valueLabel,
              style: SettingsType.body(AppColors.textSecondaryDark),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondaryDark,
              size: AppComponentSizes.iconSm,
            ),
          ],
        ),
      ),
    );
  }
}
