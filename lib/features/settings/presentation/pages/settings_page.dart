import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_breakpoints.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_group.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountCubit>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final padding = AppBreakpoints.pagePadding(context);
    final maxWidth = AppBreakpoints.contentMaxWidth(context);

    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.deleted && context.mounted) {
          context.go(AppRoutes.login);
        }
      },
      child: ColoredBox(
        color: AppColors.backgroundDark,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: padding.copyWith(
                  top: AppSpacing.md,
                  bottom: AppSpacing.huge,
                ),
                children: [
                  const _SettingsHeader(),
                  const SizedBox(height: AppSpacing.xxl),
                  SettingsSection(
                    title: 'General',
                    children: [
                      SettingsNavRow(
                        label: 'Appearance',
                        subtitle: 'Theme and accent color',
                        icon: Icons.palette_outlined,
                        iconColor: const Color(0xFFFF8A5C),
                        iconBackground: const Color(0x33FF8A5C),
                        onTap: () => context.push(AppRoutes.appearance),
                      ),
                      SettingsNavRow(
                        label: 'Notifications',
                        subtitle: 'Alerts and delivery',
                        icon: Icons.notifications_none_rounded,
                        iconColor: const Color(0xFFFF6B8A),
                        iconBackground: const Color(0x33FF6B8A),
                        onTap: () =>
                            context.push(AppRoutes.notificationSettings),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SettingsSection(
                    title: 'Widget',
                    children: [
                      SettingsNavRow(
                        label: 'Widget privacy',
                        subtitle: 'Who can appear on your home screen',
                        icon: Icons.shield_outlined,
                        iconColor: const Color(0xFF7EC8E3),
                        iconBackground: const Color(0x337EC8E3),
                        onTap: () => context.push(AppRoutes.widgetPrivacy),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SettingsSection(
                    title: 'Privacy & safety',
                    children: [
                      SettingsNavRow(
                        label: 'Blocked users',
                        subtitle: 'Manage blocked accounts',
                        icon: Icons.block_flipped,
                        iconColor: const Color(0xFFE8C39E),
                        iconBackground: const Color(0x33E8C39E),
                        onTap: () => context.push(AppRoutes.blockedUsers),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SettingsSection(
                    title: 'Support',
                    children: [
                      SettingsNavRow(
                        label: 'Help center',
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF9AE6B4),
                        iconBackground: const Color(0x339AE6B4),
                        onTap: () => context.push(AppRoutes.help),
                      ),
                      SettingsNavRow(
                        label: 'Report a problem',
                        icon: Icons.flag_outlined,
                        iconColor: const Color(0xFFFFB86C),
                        iconBackground: const Color(0x33FFB86C),
                        onTap: () => context.push(AppRoutes.reportProblem),
                      ),
                      SettingsNavRow(
                        label: 'Terms of Service',
                        icon: Icons.description_outlined,
                        iconColor: AppColors.textTertiaryDark,
                        iconBackground: const Color(0x1AFFFFFF),
                        onTap: () => context.push(AppRoutes.termsOfService),
                      ),
                      SettingsNavRow(
                        label: 'Privacy Policy',
                        icon: Icons.lock_outline_rounded,
                        iconColor: AppColors.textTertiaryDark,
                        iconBackground: const Color(0x1AFFFFFF),
                        onTap: () => context.push(AppRoutes.privacyPolicy),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SettingsSection(
                    title: 'Account',
                    children: [
                      SettingsNavRow(
                        label: 'Sign out',
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.textSecondaryDark,
                        iconBackground: const Color(0x1AFFFFFF),
                        onTap: () => _logout(context),
                      ),
                      SettingsNavRow(
                        label: 'Delete account',
                        subtitle: 'Permanently remove your profile',
                        icon: Icons.person_remove_outlined,
                        iconColor: AppColors.error,
                        iconBackground: const Color(0x33C42B3A),
                        destructive: true,
                        showChevron: false,
                        onTap: () => _deleteAccount(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await MomentBottomSheet.confirm(
      context,
      title: 'Sign out?',
      message: "You'll need to sign in again to use Moment.",
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !context.mounted) return;

    await context.read<AccountCubit>().logout();
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await MomentBottomSheet.confirm(
      context,
      title: 'Delete account?',
      message:
          'This permanently removes your account and profile. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    await context.read<AccountCubit>().deleteAccount();
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.textPrimaryDark,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: SettingsType.title(AppColors.textPrimaryDark).copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  height: 1.25,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Privacy and preferences',
                style: SettingsType.caption(AppColors.textTertiaryDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
