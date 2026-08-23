import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/friends/presentation/cubit/friends_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BlockedUsersCubit>()..load(),
      child: const _BlockedUsersView(),
    );
  }
}

class _BlockedUsersView extends StatelessWidget {
  const _BlockedUsersView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BlockedUsersCubit, BlockedUsersState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        return MomentScaffold(
          appBar: MomentAppBar(
            title: 'Blocked users',
            centerTitle: true,
            leading: IconButton(
              icon: Icon(AppIcons.back, size: 18),
              onPressed: () => context.pop(),
            ),
          ),
          body: switch (state.status) {
            BlockedUsersStatus.loading ||
            BlockedUsersStatus.initial => Center(child: MomentLoading()),
            BlockedUsersStatus.failure => MomentErrorState(
              message: state.errorMessage ?? 'Could not load blocked users.',
              actionLabel: 'Retry',
              onAction: () => context.read<BlockedUsersCubit>().load(),
            ),
            BlockedUsersStatus.loaded when state.users.isEmpty =>
              const _BlockedEmptyState(),
            BlockedUsersStatus.loaded => ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: state.users.length,
              separatorBuilder: (_, _) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final blocked = state.users[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.borderDark.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      MomentAvatar(
                        name: blocked.profile.displayName,
                        imageUrl: blocked.profile.avatarUrl,
                        size: 44,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blocked.profile.displayName,
                              style: SettingsType.title(AppColors.textPrimaryDark)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '@${blocked.profile.username}',
                              style: SettingsType.caption(
                                AppColors.textTertiaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      MomentButton(
                        label: 'Unblock',
                        expanded: false,
                        variant: MomentButtonVariant.secondary,
                        onPressed: () => context
                            .read<BlockedUsersCubit>()
                            .unblock(blocked.profile.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          },
        );
      },
    );
  }
}

class _BlockedEmptyState extends StatelessWidget {
  const _BlockedEmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SizedBox(height: AppSpacing.xxl),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/blocked_empty.png',
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              height: 180,
              alignment: Alignment.center,
              child: Icon(
                Icons.block_rounded,
                size: 80,
                color: AppColors.violet.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        Text(
          'No blocked users yet',
          textAlign: TextAlign.center,
          style: SettingsType.title(AppColors.textPrimaryDark).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "When you block someone, they'll appear here.",
          textAlign: TextAlign.center,
          style: SettingsType.body(AppColors.textTertiaryDark),
        ),
        SizedBox(height: AppSpacing.xxl),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentSoftDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: AppColors.violet,
                  size: 22,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You're in control",
                      style: SettingsType.title(AppColors.textPrimaryDark)
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Block users to keep your experience safe and comfortable.',
                      style: SettingsType.caption(AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
