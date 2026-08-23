import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_controls.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/settings/presentation/cubit/notification_settings_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_group.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationSettingsCubit>()..load(),
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
      builder: (context, state) {
        final cubit = context.read<NotificationSettingsCubit>();
        final prefs = state.preferences;
        final pushOn = prefs.pushEnabled;
        final isLoading = state.status == NotificationSettingsStatus.loading ||
            state.status == NotificationSettingsStatus.initial;

        return MomentScaffold(
          appBar: MomentAppBar(
            title: 'Notification settings',
            centerTitle: true,
            leading: IconButton(
              icon: Icon(AppIcons.back, size: 18),
              onPressed: state.isSaving ? null : () => context.pop(),
            ),
          ),
          body: isLoading
              ? Center(child: MomentLoading())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.huge,
                  ),
                  children: [
                    Text(
                      'Control your alerts',
                      style: SettingsType.title(AppColors.textPrimaryDark)
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Choose what Moment can notify you about.',
                      style: SettingsType.caption(AppColors.textTertiaryDark)
                          .copyWith(fontWeight: FontWeight.w400, fontSize: 11),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    SettingsSection(
                      title: 'Push',
                      subtitle: 'Alerts on this device',
                      children: [
                        _SimpleToggleRow(
                          label: 'Push notifications',
                          value: pushOn,
                          enabled: !state.isSaving,
                          onChanged: cubit.setPushEnabled,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xxl),
                    SettingsSection(
                      title: 'Activity',
                      subtitle: pushOn
                          ? 'Pick the updates you care about'
                          : 'Turn on push notifications above',
                      children: [
                        _PrefToggle(
                          icon: Icons.photo_camera_outlined,
                          label: 'Moments',
                          subtitle: 'When friends send you a moment',
                          value: prefs.moments,
                          enabled: pushOn && !state.isSaving,
                          onChanged: cubit.setMoments,
                        ),
                        _PrefToggle(
                          icon: Icons.person_add_alt_1_outlined,
                          label: 'Friend requests',
                          subtitle: 'New requests and acceptances',
                          value: prefs.friendRequests,
                          enabled: pushOn && !state.isSaving,
                          onChanged: cubit.setFriendRequests,
                        ),
                        _PrefToggle(
                          icon: Icons.alternate_email_rounded,
                          label: 'Mentions',
                          subtitle: 'When someone mentions you',
                          value: prefs.mentions,
                          enabled: pushOn && !state.isSaving,
                          onChanged: cubit.setMentions,
                        ),
                        _PrefToggle(
                          icon: Icons.auto_stories_outlined,
                          label: 'Memories',
                          subtitle: 'When a memory is ready to view',
                          value: prefs.memories,
                          enabled: pushOn && !state.isSaving,
                          onChanged: cubit.setMemories,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xxl),
                    SettingsSection(
                      title: 'Account',
                      children: [
                        _PrefToggle(
                          icon: Icons.shield_outlined,
                          label: 'Security',
                          subtitle: 'Login alerts and account changes',
                          value: prefs.security,
                          enabled: pushOn && !state.isSaving,
                          onChanged: cubit.setSecurity,
                        ),
                        _PrefToggle(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email digest',
                          subtitle: 'Weekly summary of your activity',
                          value: prefs.emailDigest,
                          enabled: !state.isSaving,
                          onChanged: cubit.setEmailDigest,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.borderDark.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.violet,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'System alerts for security and billing may still be sent when required.',
                              style: SettingsType.caption(
                                AppColors.textTertiaryDark,
                              ).copyWith(fontWeight: FontWeight.w400, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _PrefToggle extends StatelessWidget {
  const _PrefToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        10,
        AppSpacing.sm,
        10,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.accentSoftDark
                  : AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: enabled ? AppColors.violet : AppColors.textTertiaryDark,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: SettingsType.body(
                    enabled
                        ? AppColors.textPrimaryDark
                        : AppColors.textTertiaryDark,
                  ).copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                Text(
                  subtitle,
                  style: SettingsType.caption(AppColors.textTertiaryDark)
                      .copyWith(fontWeight: FontWeight.w400, fontSize: 10),
                ),
              ],
            ),
          ),
          MomentSwitch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _SimpleToggleRow extends StatelessWidget {
  const _SimpleToggleRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        10,
        AppSpacing.sm,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: SettingsType.body(AppColors.textPrimaryDark)
                  .copyWith(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          MomentSwitch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
