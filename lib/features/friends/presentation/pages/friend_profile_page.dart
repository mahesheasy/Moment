import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_controls.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/presentation/cubit/friends_cubit.dart';
import 'package:moment/features/friends/presentation/theme/friend_profile_theme.dart';
import 'package:moment/features/friends/presentation/widgets/friend_profile/friend_profile_blocked_notice.dart';
import 'package:moment/features/friends/presentation/widgets/friend_profile/friend_profile_about_section.dart';
import 'package:moment/features/friends/presentation/widgets/friend_profile/friend_profile_actions.dart';
import 'package:moment/features/friends/presentation/widgets/friend_profile/friend_profile_hero.dart';
import 'package:moment/features/friends/presentation/widgets/friend_profile/friend_profile_private_space_card.dart';
import 'package:moment/features/friends/presentation/widgets/friend_profile/friend_profile_stats.dart';
import 'package:moment/features/friends/presentation/widgets/friend_profile/friend_profile_top_bar.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class FriendProfilePage extends StatelessWidget {
  const FriendProfilePage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FriendProfileCubit>(param1: userId)..load(),
      child: _FriendProfileView(userId: userId),
    );
  }
}

class _FriendProfileView extends StatelessWidget {
  const _FriendProfileView({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FriendProfileCubit, FriendProfileState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.actionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.actionMessage!)),
          );
        }
        if (state.shouldRefreshFriendsList && context.mounted) {
          context.pop(true);
        }
      },
      builder: (context, state) {
        if (state.status == FriendProfileStatus.loading ||
            state.status == FriendProfileStatus.initial) {
          return _FriendProfileShell(
            child: const FriendProfileLoadingBody(),
          );
        }

        final profile = state.profile;
        if (profile == null) {
          return _FriendProfileShell(
            onBack: () => context.pop(),
            child: MomentErrorState(
              message: state.errorMessage ?? 'Could not load profile.',
              actionLabel: 'Try again',
              onAction: () => context.read<FriendProfileCubit>().load(),
            ),
          );
        }

        final isActing = state.status == FriendProfileStatus.acting;
        final isFriend = state.relationship == FriendRelationship.friends;
        final isBlocked = state.relationship == FriendRelationship.blocked;
        final isBlockedBy = state.relationship == FriendRelationship.blockedBy;
        final isBlockedState = isBlocked || isBlockedBy;
        final stats = buildFriendProfileStats(
          isFriend: isFriend,
          mutualFriendCount: state.mutualFriendCount,
          friendsSince: state.friendsSince,
          joinedAt: profile.createdAt,
        );
        final aboutRows = buildFriendProfileAboutRows(
          joinedAt: profile.createdAt,
          friendsSince: isFriend && !isBlockedState ? state.friendsSince : null,
        );

        return _FriendProfileShell(
          onBack: () => context.pop(),
          onMenu: isBlockedState
              ? null
              : () => _showOverflowMenu(context, profile, isActing),
          bottomBar: FriendProfileActions(
            userId: userId,
            profile: profile,
            relationship: state.relationship,
            pendingRequestId: state.pendingRequestId,
            isActing: isActing,
            onMessage: () => _openPrivateSpace(context, profile),
            onPrivateSpace: () => _openPrivateSpace(context, profile),
            onRemoveFriend: () => _confirmRemoveFriend(context, profile),
            onAddFriend: () =>
                context.read<FriendProfileCubit>().sendRequest(),
            onAccept: () {
              final id = state.pendingRequestId;
              if (id != null) {
                context.read<FriendProfileCubit>().acceptRequest(id);
              }
            },
            onDecline: () {
              final id = state.pendingRequestId;
              if (id != null) {
                context.read<FriendProfileCubit>().rejectRequest(id);
              }
            },
            onCancelRequest: () {
              final id = state.pendingRequestId;
              if (id != null) {
                context.read<FriendProfileCubit>().cancelRequest(id);
              }
            },
            onBlock: () => _confirmBlock(context, profile),
            onReport: () => _showReportSheet(context),
            onUnblock: () => _confirmUnblock(context, profile),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              FriendProfileHero(
                profile: profile,
                showOnlineStatus: isFriend && !isBlockedState,
              ),
              if (isBlockedState)
                FriendProfileBlockedNotice(
                  profile: profile,
                  relationship: state.relationship,
                ),
              if (stats.isNotEmpty && !isBlockedState) ...[
                const SizedBox(height: 28),
                FriendProfileStats(stats: stats),
              ],
              if (isFriend && !isBlockedState) ...[
                const SizedBox(height: 28),
                FriendProfilePrivateSpaceCard(
                  onTap: () => _openPrivateSpace(context, profile),
                ),
              ],
              if (aboutRows.isNotEmpty) ...[
                const SizedBox(height: 28),
                FriendProfileAboutSection(
                  title: 'About ${profile.displayName.split(' ').first}',
                  rows: aboutRows,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  void _openPrivateSpace(BuildContext context, UserProfile profile) {
    context.push(AppRoutes.chatThread(userId), extra: profile);
  }

  Future<void> _confirmRemoveFriend(
    BuildContext context,
    UserProfile profile,
  ) async {
    final confirmed = await MomentDialog.confirm(
      context,
      title: 'Remove friend?',
      message: 'You can send a new request later.',
      confirmLabel: 'Remove',
    );
    if (confirmed == true && context.mounted) {
      await context.read<FriendProfileCubit>().removeFriend();
      if (context.mounted) context.pop();
    }
  }

  Future<void> _confirmBlock(BuildContext context, UserProfile profile) async {
    final confirmed = await MomentDialog.confirm(
      context,
      title: 'Block ${profile.displayName}?',
      message: 'They will not be able to send you requests or moments.',
      confirmLabel: 'Block',
    );
    if (confirmed == true && context.mounted) {
      await context.read<FriendProfileCubit>().blockUser();
    }
  }

  Future<void> _confirmUnblock(
    BuildContext context,
    UserProfile profile,
  ) async {
    final confirmed = await MomentDialog.confirm(
      context,
      title: 'Unblock ${profile.displayName}?',
      message: 'They will be able to send you friend requests and messages again.',
      confirmLabel: 'Unblock',
    );
    if (confirmed == true && context.mounted) {
      await context.read<FriendProfileCubit>().unblockUser();
    }
  }

  Future<void> _showOverflowMenu(
    BuildContext context,
    UserProfile profile,
    bool isActing,
  ) async {
    if (isActing) return;

    final action = await showModalBottomSheet<_OverflowAction>(
      context: context,
      backgroundColor: FriendProfileTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.block_rounded),
                title: const Text('Block'),
                onTap: () => Navigator.pop(context, _OverflowAction.block),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report'),
                onTap: () => Navigator.pop(context, _OverflowAction.report),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case _OverflowAction.block:
        await _confirmBlock(context, profile);
      case _OverflowAction.report:
        await _showReportSheet(context);
    }
  }

  Future<void> _showReportSheet(BuildContext context) async {
    const reasons = ['Spam', 'Harassment', 'Inappropriate content', 'Other'];
    var selected = reasons.first;
    final detailsController = TextEditingController();

    await MomentBottomSheet.show<void>(
      context,
      title: 'Report user',
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...reasons.map(
                (reason) => MomentRadioRow<String>(
                  label: reason,
                  value: reason,
                  groupValue: selected,
                  onChanged: (value) {
                    if (value != null) setState(() => selected = value);
                  },
                ),
              ),
              TextField(
                controller: detailsController,
                style: TextStyle(color: AppColors.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: 'Details (optional)',
                  labelStyle: TextStyle(color: AppColors.textTertiaryDark),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              MomentButton(
                label: 'Submit report',
                onPressed: () {
                  context.read<FriendProfileCubit>().reportUser(
                    selected,
                    details: detailsController.text,
                  );
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
    detailsController.dispose();
  }
}

enum _OverflowAction { block, report }

class _FriendProfileShell extends StatelessWidget {
  const _FriendProfileShell({
    required this.child,
    this.onBack,
    this.onMenu,
    this.bottomBar,
  });

  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FriendProfileTheme.backgroundBottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: FriendProfileTheme.backgroundGradient,
            ),
            child: const SizedBox.expand(),
          ),
          const FriendProfileAmbientGlow(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FriendProfileTopBar(
                  onBack: onBack ?? () => context.pop(),
                  onMenu: onMenu,
                ),
                Expanded(child: child),
                if (bottomBar != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: bottomBar!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
