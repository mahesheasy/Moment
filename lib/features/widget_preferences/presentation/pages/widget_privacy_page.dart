import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
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
                  headerTitle: previewPerson.name,
                  forcePrivacyMode: draft.privacyMode,
                  previewSize: 228,
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
                title: 'Apply to',
                children: [
                  _ScopeRow(
                    label: 'Everyone',
                    subtitle: 'All senders use this privacy mode',
                    selected: draft.privacyPersonId == null,
                    onTap: () => cubit.setPrivacyPerson(null),
                  ),
                  ...state.friends.map(
                    (friend) => _ScopeRow(
                      label: friend.profile.displayName,
                      subtitle: 'Only ${friend.profile.displayName}\'s moments',
                      selected: draft.privacyPersonId == friend.profile.id,
                      leading: MomentAvatar(
                        name: friend.profile.displayName,
                        imageUrl: friend.profile.avatarUrl,
                        size: 28,
                      ),
                      onTap: () => cubit.setPrivacyPerson(friend.profile.id),
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
    if (draft.privacyPersonId != null) {
      final friend = state.friends
          .where((f) => f.profile.id == draft.privacyPersonId)
          .map((f) => f.profile.displayName)
          .firstOrNull;
      return (id: draft.privacyPersonId!, name: friend ?? 'Friend');
    }
    return (id: 'preview-sender', name: 'Jay');
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

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 12,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: SettingsType.title(AppColors.textPrimaryDark),
                  ),
                  Text(
                    subtitle,
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
