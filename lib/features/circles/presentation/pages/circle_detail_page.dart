import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/config/app_features.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/empty_moments_card.dart';
import 'package:moment/core/widgets/moment_cached_image.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/circles/presentation/circles_list_refresh.dart';
import 'package:moment/features/circles/presentation/cubit/circle_detail_cubit.dart';
import 'package:moment/features/circles/presentation/widgets/circle_icon.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';
import 'package:moment/features/moments/presentation/widgets/reaction_picker_sheet.dart';
import 'package:moment/features/prompts/presentation/cubit/prompt_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';
import 'package:moment/features/subscription/domain/repositories/subscription_repository.dart';

class CircleDetailPage extends StatelessWidget {
  const CircleDetailPage({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CircleDetailCubit>(param1: circleId)..load(),
      child: BlocProvider(
        create: (_) => sl<PromptCubit>()..loadToday(),
        child: _CircleDetailView(circleId: circleId),
      ),
    );
  }
}

String _normalizeImageMimeType(String? mimeType) {
  final raw = (mimeType ?? 'image/jpeg').toLowerCase();
  if (raw == 'image/jpg') return 'image/jpeg';
  return switch (raw) {
    'image/jpeg' || 'image/png' || 'image/webp' => raw,
    _ => 'image/jpeg',
  };
}

class _CircleDetailView extends StatelessWidget {
  const _CircleDetailView({required this.circleId});

  final String circleId;

  Future<void> _showMembers(
    BuildContext context, {
    required bool isOwner,
  }) async {
    final cubit = context.read<CircleDetailCubit>();
    final circle = cubit.state.circle;
    if (circle == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: cubit,
          child: _MembersSheet(
            isOwner: isOwner,
            onAdd: () {
              Navigator.of(sheetContext).pop();
              _showAddMemberSheet(context);
            },
            onLeave: () {
              Navigator.of(sheetContext).pop();
              _confirmLeaveCircle(context);
            },
            onDelete: () {
              Navigator.of(sheetContext).pop();
              _confirmDeleteCircle(context, circle);
            },
          ),
        );
      },
    );
  }

  Future<void> _showAddMemberSheet(BuildContext context) async {
    final cubit = context.read<CircleDetailCubit>();
    final state = cubit.state;
    if (state.friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add friends first, then invite them here.')),
      );
      await context.push(AppRoutes.friends);
      if (context.mounted) await cubit.load();
      return;
    }

    if (state.members.length >= CircleLimits.maxMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A circle can have at most 20 members.')),
      );
      return;
    }

    final addable = state.addableFriends;
    if (addable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All friends are already in this circle.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                'Add friend',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              for (final friend in addable)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: MomentAvatar(
                    name: friend.profile.displayName,
                    imageUrl: friend.profile.avatarUrl,
                  ),
                  title: Text(
                    friend.profile.displayName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '@${friend.profile.username}',
                    style: TextStyle(color: AppColors.textTertiaryDark),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await cubit.addMember(friend.profile.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    final prompt = context.read<PromptCubit>().state.prompt;
    if (prompt != null) {
      await context.push(
        AppRoutes.cameraForPrompt(circleId: circleId, promptId: prompt.id),
      );
    } else {
      await context.push(AppRoutes.cameraForCircle(circleId));
    }
    if (context.mounted) {
      await context.read<CircleDetailCubit>().load();
    }
  }

  Future<void> _returnToCirclesList(BuildContext context) async {
    sl<CirclesListRefresh>().requestRefresh();
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(AppRoutes.circles);
    }
  }

  Future<void> _renameCircle(BuildContext context, Circle circle) async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _RenameCircleDialog(initialName: circle.name),
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    await context.read<CircleDetailCubit>().renameCircle(name);
    sl<CirclesListRefresh>().requestRefresh();
  }

  Future<void> _pickCirclePhoto(BuildContext context, Circle circle) async {
    if (!AppFeatures.momentPlusCirclePhotosUnlocked) {
      final offeringResult = await sl<SubscriptionRepository>().getOffering();
      final isPremium = switch (offeringResult) {
        Success(:final value) => value.isPremium,
        Failed() => false,
      };
      if (!isPremium) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Custom circle photos are a Moment+ feature.'),
          ),
        );
        await context.push(AppRoutes.premium);
        return;
      }
    }

    if (!context.mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined),
                title: Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined),
                title: Text('Take a photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (file == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    await context.read<CircleDetailCubit>().uploadCirclePhoto(
      bytes: bytes,
      mimeType: _normalizeImageMimeType(file.mimeType),
    );
  }

  Future<void> _confirmLeaveCircle(BuildContext context) async {
    final confirmed = await MomentDialog.confirm(
      context,
      title: 'Leave circle?',
      message: 'You will no longer see moments shared to this circle.',
      confirmLabel: 'Leave',
    );
    if (confirmed != true || !context.mounted) return;

    final left = await context.read<CircleDetailCubit>().leaveCircle();
    if (left && context.mounted) {
      await _returnToCirclesList(context);
    }
  }

  Future<void> _confirmDeleteCircle(BuildContext context, Circle circle) async {
    final confirmed = await MomentDialog.confirm(
      context,
      title: 'Delete "${circle.name}"?',
      message:
          'This permanently removes the circle for everyone. This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed != true || !context.mounted) return;

    final deleted = await context.read<CircleDetailCubit>().deleteCircle();
    if (deleted && context.mounted) {
      await _returnToCirclesList(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CircleDetailCubit, CircleDetailState>(
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
        final circle = state.circle;
        if (state.status == CircleDetailStatus.loading && circle == null) {
          return Scaffold(body: Center(child: MomentLoading()));
        }
        if (state.status == CircleDetailStatus.failure && circle == null) {
          return Scaffold(
            appBar: AppBar(),
            body: MomentErrorState(
              message: state.errorMessage ?? 'Could not load circle.',
              actionLabel: 'Retry',
              onAction: () => context.read<CircleDetailCubit>().load(),
            ),
          );
        }
        if (circle == null) {
          return Scaffold(body: Center(child: MomentLoading()));
        }

        final latest = state.latestMoment;
        final me = sl<AuthRepository>().currentUserId;
        final isOwner = me == circle.ownerId;

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.circles);
                        }
                      },
                      icon: Icon(AppIcons.back, size: 18),
                      color: Colors.white,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: 8),
                _CircleHeader(
                  circle: circle,
                  members: state.members,
                  avatarCacheKey: state.avatarCacheKey,
                  currentUserId: me,
                  onMembers: () => _showMembers(context, isOwner: isOwner),
                  onInvite: isOwner ? () => _showAddMemberSheet(context) : null,
                  onRename: isOwner
                      ? () => _renameCircle(context, circle)
                      : null,
                  onPhotoTap: isOwner
                      ? () => _pickCirclePhoto(context, circle)
                      : null,
                  canEditPhoto: isOwner,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: AppColors.violet,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Latest moment',
                      style: SettingsType.title(Colors.white),
                    ),
                    // Spacer(),
                    // if (state.moments.isNotEmpty)
                    //   GestureDetector(
                    //     onTap: () =>
                    //         context.push(AppRoutes.circleMoments(circleId)),
                    //     child: Row(
                    //       children: [
                    //         Text(
                    //           'See all',
                    //           style: SettingsType.caption(AppColors.violet),
                    //         ),
                    //         Icon(
                    //           Icons.chevron_right_rounded,
                    //           size: 14,
                    //           color: AppColors.violet,
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                  ],
                ),
                SizedBox(height: 10),
                if (latest == null)
                  _EmptyLatest(onCamera: () => _openCamera(context))
                else
                  _LatestMomentCard(
                    moment: latest,
                    reactions: state.reactionsByMomentId[latest.id],
                    onOpen: () => context.push(AppRoutes.moment(latest.id)),
                  ),
                SizedBox(height: 14),
                _ActionRow(
                  onReact: latest == null
                      ? null
                      : () async {
                          final type = await ReactionPickerSheet.show(context);
                          if (type != null && context.mounted) {
                            await context
                                .read<CircleDetailCubit>()
                                .reactToLatest(type);
                          }
                        },
                  onPing: latest == null || latest.sender.id == me
                      ? null
                      : () => context.read<CircleDetailCubit>().pingLatest(),
                  onCamera: () => _openCamera(context),
                ),
                SizedBox(height: 24),
                GestureDetector(
                  onTap: state.moments.isEmpty
                      ? () => _openCamera(context)
                      : () => context.push(AppRoutes.circleMoments(circleId)),
                  child: Row(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 14,
                        color: AppColors.textSecondaryDark,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Moments together',
                        style: SettingsType.title(Colors.white),
                      ),
                      Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.textTertiaryDark,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                if (state.moments.isEmpty)
                  GestureDetector(
                    onTap: () => _openCamera(context),
                    child: Text(
                      'Share a moment to this circle to see it here.',
                      style: SettingsType.body(AppColors.textTertiaryDark),
                    ),
                  )
                else
                  _TogetherStrip(
                    moments: state.moments,
                    reactionsByMomentId: state.reactionsByMomentId,
                    onTap: (moment) =>
                        context.push(AppRoutes.moment(moment.id)),
                    onSeeAll: () =>
                        context.push(AppRoutes.circleMoments(circleId)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CircleHeader extends StatelessWidget {
  const _CircleHeader({
    required this.circle,
    required this.members,
    required this.onMembers,
    this.avatarCacheKey = 0,
    this.onPhotoTap,
    this.onInvite,
    this.onRename,
    this.canEditPhoto = false,
    this.currentUserId,
  });

  final Circle circle;
  final List<CircleMember> members;
  final int avatarCacheKey;
  final VoidCallback onMembers;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onInvite;
  final VoidCallback? onRename;
  final bool canEditPhoto;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onPhotoTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleIcon(
                    circle: circle,
                    size: 56,
                    radius: 14,
                    imageCacheKey: avatarCacheKey,
                  ),
                  if (canEditPhoto)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.violet,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.backgroundDark,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          circle.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SettingsType.title(
                            Colors.white,
                          ).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (onRename != null) ...[
                        SizedBox(width: 6),
                        GestureDetector(
                          onTap: onRename,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: AppColors.textTertiaryDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                    style: SettingsType.caption(AppColors.textTertiaryDark),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 11,
                        color: AppColors.textTertiaryDark.withValues(
                          alpha: 0.9,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Private circle',
                        style: SettingsType.caption(AppColors.textTertiaryDark),
                      ),
                    ],
                  ),
                  if (canEditPhoto) ...[
                    SizedBox(height: 2),
                    Text(
                      'You manage this circle',
                      style: SettingsType.caption(
                        AppColors.violet,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            if (onInvite != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: AppColors.bloomGradient,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onInvite,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_add_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Invite',
                            style: SettingsType.caption(
                              Colors.white,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        ...members
            .take(3)
            .map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: onMembers,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      MomentAvatar(
                        name: member.profile.displayName,
                        imageUrl: member.profile.avatarUrl,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _memberLabel(member, currentUserId),
                          style: SettingsType.body(
                            Colors.white,
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (member.isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevatedDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Admin',
                            style: SettingsType.caption(
                              AppColors.textSecondaryDark,
                            ),
                          ),
                        ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.textTertiaryDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }

  String _memberLabel(CircleMember member, String? currentUserId) {
    final name = member.profile.displayName;
    if (currentUserId != null && member.profile.id == currentUserId) {
      return '$name (You)';
    }
    return name;
  }
}

class _CircleOptionTile extends StatelessWidget {
  const _CircleOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.errorDark : Colors.white;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _LatestMomentCard extends StatelessWidget {
  const _LatestMomentCard({
    required this.moment,
    required this.onOpen,
    this.reactions,
  });

  final Moment moment;
  final VoidCallback onOpen;
  final MomentReactionSummary? reactions;

  @override
  Widget build(BuildContext context) {
    final caption = moment.caption?.trim();
    final hasCaption = caption != null && caption.isNotEmpty;

    return GestureDetector(
      onTap: onOpen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (moment.imageUrl == null)
                ColoredBox(color: AppColors.photoPlaceholderDark)
              else
                MomentCachedImage(
                  imageUrl: moment.imageUrl!,
                  fit: BoxFit.cover,
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x55000000),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xCC000000),
                    ],
                    stops: [0, 0.2, 0.55, 1],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: _MomentTimeBadge(time: moment.createdAt),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasCaption) ...[
                      Text(
                        caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SettingsType.body(
                          Colors.white,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        MomentAvatar(
                          name: moment.sender.displayName,
                          imageUrl: moment.sender.avatarUrl,
                          size: 22,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${moment.sender.displayName} · ${relativeTimeAgo(moment.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SettingsType.caption(
                              Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        _ReactionPill(summary: reactions),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLatest extends StatelessWidget {
  const _EmptyLatest({required this.onCamera});

  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return EmptyMomentsCard(
      title: 'Be the first to share a moment',
      subtitle: 'Send a photo to everyone in this circle.',
      buttonLabel: 'Open camera',
      onButtonTap: onCamera,
      onTap: onCamera,
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onReact,
    required this.onPing,
    required this.onCamera,
  });

  final VoidCallback? onReact;
  final VoidCallback? onPing;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: AppIcons.heart,
                label: 'React',
                subtitle: 'Show how you feel',
                onTap: onReact,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.borderDark.withValues(alpha: 0.6),
            ),
            Expanded(
              child: _ActionCard(
                icon: AppIcons.notifications,
                label: 'Ping',
                subtitle: 'Notify circle',
                onTap: onPing,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.borderDark.withValues(alpha: 0.6),
            ),
            Expanded(
              child: _ActionCard(
                icon: AppIcons.camera,
                label: 'Camera',
                subtitle: 'Capture moment',
                onTap: onCamera,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: enabled ? AppColors.violet : AppColors.textTertiaryDark,
            ),
            SizedBox(height: 5),
            Text(
              label,
              style: SettingsType.caption(
                enabled ? Colors.white : AppColors.textTertiaryDark,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SettingsType.caption(
                AppColors.textTertiaryDark,
              ).copyWith(fontSize: 9, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

class _TogetherStrip extends StatelessWidget {
  const _TogetherStrip({
    required this.moments,
    required this.reactionsByMomentId,
    required this.onTap,
    required this.onSeeAll,
  });

  final List<Moment> moments;
  final Map<String, MomentReactionSummary> reactionsByMomentId;
  final ValueChanged<Moment> onTap;
  final VoidCallback onSeeAll;

  static const _visibleCount = 3;

  @override
  Widget build(BuildContext context) {
    final overflow = moments.length - _visibleCount;
    final visible = moments.take(_visibleCount).toList();

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length + (overflow > 0 ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (overflow > 0 && index == visible.length) {
            return _OverflowTile(count: overflow, onTap: onSeeAll);
          }
          final moment = visible[index];
          return _TogetherTile(
            moment: moment,
            reactions: reactionsByMomentId[moment.id],
            onTap: () => onTap(moment),
          );
        },
      ),
    );
  }
}

class _OverflowTile extends StatelessWidget {
  const _OverflowTile({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('+$count', style: SettingsType.title(Colors.white)),
      ),
    );
  }
}

class _TogetherTile extends StatelessWidget {
  const _TogetherTile({
    required this.moment,
    required this.onTap,
    this.reactions,
  });

  final Moment moment;
  final VoidCallback onTap;
  final MomentReactionSummary? reactions;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (moment.imageUrl == null)
                ColoredBox(color: AppColors.photoPlaceholderDark)
              else
                MomentCachedImage(
                  imageUrl: moment.imageUrl!,
                  fit: BoxFit.cover,
                ),
              if (reactions != null && reactions!.total > 0)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: _ReactionPill(summary: reactions, compact: true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionPill extends StatelessWidget {
  const _ReactionPill({required this.summary, this.compact = false});

  final MomentReactionSummary? summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (summary == null || summary!.total == 0) {
      return const SizedBox.shrink();
    }

    final sorted = summary!.counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final emojis = sorted.take(3).map((e) => e.key.emoji).join();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 8,
          vertical: compact ? 2 : 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emojis, style: TextStyle(fontSize: compact ? 9 : 11)),
            if (!compact) SizedBox(width: 4),
            Text(
              '${summary!.total}',
              style: SettingsType.caption(Colors.white).copyWith(
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentTimeBadge extends StatelessWidget {
  const _MomentTimeBadge({required this.time});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 10,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            SizedBox(width: 4),
            Text(
              _format(time),
              style: SettingsType.caption(
                Colors.white,
              ).copyWith(fontSize: 9, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime createdAt) {
    final now = DateTime.now();
    final local = createdAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final momentDay = DateTime(local.year, local.month, local.day);
    final dayDiff = today.difference(momentDay).inDays;

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final timeLabel = '$hour:$minute $period';

    if (dayDiff == 0) return 'Today, $timeLabel';
    if (dayDiff == 1) return 'Yesterday, $timeLabel';
    return timeLabel;
  }
}

class _RenameCircleDialog extends StatefulWidget {
  const _RenameCircleDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameCircleDialog> createState() => _RenameCircleDialogState();
}

class _RenameCircleDialogState extends State<_RenameCircleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Text('Rename circle'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(labelText: 'Circle name'),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text('Save'),
        ),
      ],
    );
  }
}

class _MembersSheet extends StatelessWidget {
  const _MembersSheet({
    required this.onAdd,
    required this.isOwner,
    required this.onLeave,
    required this.onDelete,
  });

  final VoidCallback onAdd;
  final bool isOwner;
  final VoidCallback onLeave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleDetailCubit, CircleDetailState>(
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Members  ·  ${state.members.length}/${CircleLimits.maxMembers}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: state.members.length >= CircleLimits.maxMembers
                          ? null
                          : onAdd,
                      child: Text('Add'),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                for (final member in state.members)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: MomentAvatar(
                      name: member.profile.displayName,
                      imageUrl: member.profile.avatarUrl,
                    ),
                    title: Text(
                      member.profile.displayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      member.isOwner ? 'Owner' : '@${member.profile.username}',
                      style: TextStyle(color: AppColors.textTertiaryDark),
                    ),
                    trailing: member.isOwner
                        ? null
                        : IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: AppColors.textTertiaryDark,
                            ),
                            onPressed: state.status == CircleDetailStatus.acting
                                ? null
                                : () => context
                                      .read<CircleDetailCubit>()
                                      .removeMember(member.profile.id),
                          ),
                    onTap: () =>
                        context.push(AppRoutes.friend(member.profile.id)),
                  ),
                if (isOwner) ...[
                  const SizedBox(height: 16),
                  _CircleOptionTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete circle',
                    destructive: true,
                    onTap: onDelete,
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  _CircleOptionTile(
                    icon: Icons.logout_rounded,
                    label: 'Leave circle',
                    onTap: onLeave,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
