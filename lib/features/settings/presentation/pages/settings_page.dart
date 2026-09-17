import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_group.dart';

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
      child: MomentScaffold(
        appBar: MomentAppBar(
          title: 'Settings & Privacy',
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            onPressed: () => context.pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.sm,
            AppSpacing.xxl,
            AppSpacing.huge,
          ),
          children: [
            SettingsSection(
              title: 'Appearance',
              children: [
                SettingsNavRow(
                  label: 'Theme & accent',
                  onTap: () => context.push(AppRoutes.appearance),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SettingsSection(
              title: 'Widget',
              children: [
                SettingsNavRow(
                  label: 'Widget customize',
                  onTap: () => context.push(AppRoutes.widgetCustomize),
                ),
                SettingsNavRow(
                  label: 'Widget privacy',
                  onTap: () => context.push(AppRoutes.widgetPrivacy),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SettingsSection(
              title: 'Account',
              children: [
                SettingsNavRow(
                  label: 'Notifications',
                  onTap: () => context.push(AppRoutes.notificationSettings),
                ),
                SettingsNavRow(
                  label: 'Blocked users',
                  onTap: () => context.push(AppRoutes.blockedUsers),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SettingsSection(
              title: 'Support',
              children: [
                SettingsNavRow(
                  label: 'Help',
                  onTap: () => context.push(AppRoutes.help),
                ),
                SettingsNavRow(
                  label: 'Report a problem',
                  onTap: () => context.push(AppRoutes.reportProblem),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SettingsSection(
              title: 'Legal',
              children: [
                SettingsNavRow(
                  label: 'Terms of Service',
                  onTap: () => context.push(AppRoutes.termsOfService),
                ),
                SettingsNavRow(
                  label: 'Privacy Policy',
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SettingsSection(
              title: 'Session',
              children: [
                SettingsNavRow(
                  label: 'Sign out',
                  onTap: () => _logout(context),
                ),
                SettingsNavRow(
                  label: 'Delete account',
                  destructive: true,
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
          ],
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
