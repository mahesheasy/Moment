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
        if (state.savedMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.savedMessage!)));
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
        final saving = state.status == WidgetCustomizationStatus.saving;
        final previewPerson = _previewPerson(draft, state);
        final bottom = MediaQuery.paddingOf(context).bottom;

        return MomentScaffold(
          appBar: MomentAppBar(
            title: 'Widget Privacy',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              onPressed: () => context.pop(),
            ),
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + bottom),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              border: Border(
                top: BorderSide(
                  color: AppColors.borderDark.withValues(alpha: 0.8),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: AppComponentSizes.buttonHeightLg,
              child: FilledButton(
                onPressed: saving ? null : cubit.savePrivacy,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor:
                      AppColors.violet.withValues(alpha: 0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.lgAll,
                  ),
                  textStyle: SettingsType.title(Colors.white),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            children: [
              Text(
                'Choose how moments appear on your home screen.',
                style: SettingsType.body(AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 24),
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
                  previewSize: 228,
                  streakCount: state.previewStreakCount,
                ),
              ),
              const SizedBox(height: 28),
              SettingsSection(
                title: 'Mode',
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
                title: 'Per-person overrides',
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        final override = draft.privacyOverrides[senderId];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  senderName,
                  style: SettingsType.title(AppColors.textPrimaryDark),
                ),
              ),
              ListTile(
                title: Text(
                  'Default (${draft.privacyMode.label})',
                  style: SettingsType.body(AppColors.textPrimaryDark),
                ),
                trailing: MomentRadioIndicator(selected: override == null),
                onTap: () {
                  cubit.setPrivacyOverride(senderId, null);
                  Navigator.of(context).pop();
                },
              ),
              for (final mode in WidgetPrivacyMode.values)
                ListTile(
                  title: Text(
                    mode.label,
                    style: SettingsType.body(AppColors.textPrimaryDark),
                  ),
                  subtitle: Text(
                    mode.description,
                    style: SettingsType.caption(AppColors.textSecondaryDark),
                  ),
                  trailing: MomentRadioIndicator(selected: override == mode),
                  onTap: () {
                    cubit.setPrivacyOverride(senderId, mode);
                    Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: AppSpacing.md),
            ],
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        mode.label,
                        style: SettingsType.title(AppColors.textPrimaryDark),
                      ),
                      if (mode == WidgetPrivacyMode.blur) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Recommended',
                          style: SettingsType.caption(AppColors.violet),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode.description,
                    style: SettingsType.body(AppColors.textSecondaryDark),
                  ),
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
    final subtitle = hasOverride
        ? 'Override: ${effectiveMode.label}'
        : 'Uses default (${effectiveMode.label})';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: SettingsType.title(AppColors.textPrimaryDark),
                  ),
                  Text(
                    subtitle,
                    style: SettingsType.body(AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
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
