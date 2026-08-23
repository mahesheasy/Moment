import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_controls.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/presentation/cubit/friends_cubit.dart';

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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.actionMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
        }
      },
      builder: (context, state) {
        if (state.status == FriendProfileStatus.loading ||
            state.status == FriendProfileStatus.initial) {
          return const MomentScaffold(body: MomentLoading());
        }

        final profile = state.profile;
        if (profile == null) {
          return MomentScaffold(
            appBar: MomentAppBar(
              title: 'Profile',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
            body: MomentErrorState(
              message: state.errorMessage ?? 'Could not load profile.',
            ),
          );
        }

        final isActing = state.status == FriendProfileStatus.acting;

        return MomentScaffold(
          appBar: MomentAppBar(
            title: profile.displayName,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              children: [
                MomentAvatar(
                  name: profile.displayName,
                  imageUrl: profile.avatarUrl,
                  size: 88,
                  showBorder: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text('@${profile.username}'),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(profile.bio!, textAlign: TextAlign.center),
                ],
                const Spacer(),
                _PrimaryAction(
                  relationship: state.relationship,
                  pendingRequestId: state.pendingRequestId,
                  isActing: isActing,
                ),
                const SizedBox(height: AppSpacing.lg),
                MomentTextButton(
                  label: 'Block',
                  onPressed: isActing
                      ? null
                      : () async {
                          final confirmed = await MomentDialog.confirm(
                            context,
                            title: 'Block ${profile.displayName}?',
                            message:
                                'They will not be able to send you requests or moments.',
                            confirmLabel: 'Block',
                          );
                          if (confirmed == true && context.mounted) {
                            await context
                                .read<FriendProfileCubit>()
                                .blockUser();
                            if (context.mounted) context.pop();
                          }
                        },
                ),
                MomentTextButton(
                  label: 'Report',
                  onPressed: isActing ? null : () => _showReportSheet(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showReportSheet(BuildContext context) async {
    const reasons = ['Spam', 'Harassment', 'Inappropriate content', 'Other'];
    String selected = reasons.first;
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
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
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

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.relationship,
    required this.pendingRequestId,
    required this.isActing,
  });

  final FriendRelationship relationship;
  final String? pendingRequestId;
  final bool isActing;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FriendProfileCubit>();

    switch (relationship) {
      case FriendRelationship.friends:
        return MomentButton(
          label: 'Remove friend',
          variant: MomentButtonVariant.secondary,
          isLoading: isActing,
          onPressed: isActing
              ? null
              : () async {
                  final confirmed = await MomentDialog.confirm(
                    context,
                    title: 'Remove friend?',
                    message: 'You can send a new request later.',
                    confirmLabel: 'Remove',
                  );
                  if (confirmed == true && context.mounted) {
                    await cubit.removeFriend();
                    if (context.mounted) context.pop();
                  }
                },
        );
      case FriendRelationship.requestSent:
        return MomentButton(
          label: 'Cancel request',
          variant: MomentButtonVariant.secondary,
          isLoading: isActing,
          onPressed: isActing || pendingRequestId == null
              ? null
              : () => cubit.cancelRequest(pendingRequestId!),
        );
      case FriendRelationship.requestReceived:
        return Row(
          children: [
            Expanded(
              child: MomentButton(
                label: 'Accept',
                isLoading: isActing,
                onPressed: isActing || pendingRequestId == null
                    ? null
                    : () => cubit.acceptRequest(pendingRequestId!),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: MomentButton(
                label: 'Decline',
                variant: MomentButtonVariant.secondary,
                isLoading: isActing,
                onPressed: isActing || pendingRequestId == null
                    ? null
                    : () => cubit.rejectRequest(pendingRequestId!),
              ),
            ),
          ],
        );
      case FriendRelationship.blocked:
      case FriendRelationship.blockedBy:
        return const Text('Blocked');
      case FriendRelationship.none:
        return MomentButton(
          label: 'Add friend',
          isLoading: isActing,
          onPressed: isActing ? null : cubit.sendRequest,
        );
    }
  }
}
