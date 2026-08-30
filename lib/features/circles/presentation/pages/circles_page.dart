import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/config/app_features.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/core/theme/app_breakpoints.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/core/widgets/dashed_border.dart';
import 'package:moment/core/widgets/dark_page_chrome.dart';
import 'package:moment/core/widgets/moment_cached_image.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/circles/presentation/circles_list_refresh.dart';
import 'package:moment/features/circles/presentation/cubit/circles_cubit.dart';
import 'package:moment/features/circles/presentation/widgets/circle_icon.dart';
import 'package:moment/features/circles/presentation/widgets/circle_member_avatar_stack.dart';
import 'package:moment/features/circles/presentation/widgets/create_circle_sheet.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';
import 'package:moment/features/subscription/domain/repositories/subscription_repository.dart';

class CirclesPage extends StatelessWidget {
  const CirclesPage({super.key});

  Future<void> _openCreateSheet(
    BuildContext context, {
    CircleType? initialType,
  }) async {
    final cubit = context.read<CirclesCubit>();

    if (!AppFeatures.momentPlusCirclesUnlocked) {
      final offeringResult = await sl<SubscriptionRepository>().getOffering();
      if (!context.mounted) return;
      final isPremium = switch (offeringResult) {
        Success(:final value) => value.isPremium,
        Failed() => false,
      };
      if (!isPremium) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Circles are a Moment+ feature. Upgrade to create groups.',
            ),
          ),
        );
        await context.push(AppRoutes.premium);
        return;
      }
    }

    if (!context.mounted) return;
    final circle = await CreateCircleSheet.show(
      context,
      initialType: initialType,
      cubit: cubit,
    );
    if (circle != null && context.mounted) {
      await context.push(AppRoutes.circle(circle.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CirclesCubit>()..load(),
      child: BlocConsumer<CirclesCubit, CirclesState>(
        listener: (context, state) {
          if (state.errorMessage != null &&
              state.status == CirclesStatus.failure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final maxWidth = AppBreakpoints.contentMaxWidth(context);
          final padding = AppBreakpoints.pagePadding(context);

          return ColoredBox(
            color: AppColors.backgroundDark,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: _CirclesBody(
                    state: state,
                    padding: padding,
                    onCreate: (type) =>
                        _openCreateSheet(context, initialType: type),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CirclesBody extends StatefulWidget {
  const _CirclesBody({
    required this.state,
    required this.padding,
    required this.onCreate,
  });

  final CirclesState state;
  final EdgeInsets padding;
  final ValueChanged<CircleType?> onCreate;

  @override
  State<_CirclesBody> createState() => _CirclesBodyState();
}

enum _CircleSort { nameAz, membersDesc, recentActivity }

enum _CircleFilter { all, withMoments }

class _CirclesBodyState extends State<_CirclesBody> {
  final _searchController = TextEditingController();
  String _query = '';
  _CircleSort _sort = _CircleSort.recentActivity;
  _CircleFilter _filter = _CircleFilter.all;

  @override
  void initState() {
    super.initState();
    sl<CirclesListRefresh>().version.addListener(_handleRefreshRequest);
  }

  void _handleRefreshRequest() {
    if (!mounted) return;
    context.read<CirclesCubit>().load();
  }

  @override
  void dispose() {
    sl<CirclesListRefresh>().version.removeListener(_handleRefreshRequest);
    _searchController.dispose();
    super.dispose();
  }

  List<Circle> get _filteredCircles {
    final q = _query.trim().toLowerCase();
    var circles = widget.state.circles;
    if (q.isNotEmpty) {
      circles = circles
          .where((circle) => circle.name.toLowerCase().contains(q))
          .toList();
    }
    if (_filter == _CircleFilter.withMoments) {
      circles = circles
          .where(
            (circle) =>
                (widget.state.activityByCircleId[circle.id]?.momentCount ?? 0) >
                0,
          )
          .toList();
    }
    circles = [...circles];
    switch (_sort) {
      case _CircleSort.nameAz:
        circles.sort((a, b) => a.name.compareTo(b.name));
      case _CircleSort.membersDesc:
        circles.sort((a, b) => b.memberCount.compareTo(a.memberCount));
      case _CircleSort.recentActivity:
        circles.sort((a, b) {
          final aTime =
              widget.state.activityByCircleId[a.id]?.latestActivityAt;
          final bTime =
              widget.state.activityByCircleId[b.id]?.latestActivityAt;
          if (aTime == null && bTime == null) {
            return b.createdAt.compareTo(a.createdAt);
          }
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
    }
    return circles;
  }

  Future<void> _showFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort & filter',
                  style: SettingsType.body(AppColors.textPrimaryDark)
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                _FilterOption(
                  label: 'Recent activity',
                  selected: _sort == _CircleSort.recentActivity,
                  onTap: () {
                    setState(() => _sort = _CircleSort.recentActivity);
                    Navigator.pop(sheetContext);
                  },
                ),
                _FilterOption(
                  label: 'Name A–Z',
                  selected: _sort == _CircleSort.nameAz,
                  onTap: () {
                    setState(() => _sort = _CircleSort.nameAz);
                    Navigator.pop(sheetContext);
                  },
                ),
                _FilterOption(
                  label: 'Most members',
                  selected: _sort == _CircleSort.membersDesc,
                  onTap: () {
                    setState(() => _sort = _CircleSort.membersDesc);
                    Navigator.pop(sheetContext);
                  },
                ),
                Divider(height: 24, color: AppColors.borderDark),
                _FilterOption(
                  label: 'All circles',
                  selected: _filter == _CircleFilter.all,
                  onTap: () {
                    setState(() => _filter = _CircleFilter.all);
                    Navigator.pop(sheetContext);
                  },
                ),
                _FilterOption(
                  label: 'With moments only',
                  selected: _filter == _CircleFilter.withMoments,
                  onTap: () {
                    setState(() => _filter = _CircleFilter.withMoments);
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCircleCardMenu(BuildContext context, Circle circle) async {
    final me = sl<AuthRepository>().currentUserId;
    final isOwner = me != null && circle.ownerId == me;

    final action = await showModalBottomSheet<_CircleCardMenuAction>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CircleCardMenuTile(
                icon: Icons.open_in_new_rounded,
                label: 'Open circle',
                onTap: () =>
                    Navigator.pop(sheetContext, _CircleCardMenuAction.open),
              ),
              if (isOwner)
                _CircleCardMenuTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete circle',
                  destructive: true,
                  onTap: () =>
                      Navigator.pop(sheetContext, _CircleCardMenuAction.delete),
                )
              else
                _CircleCardMenuTile(
                  icon: Icons.logout_rounded,
                  label: 'Leave circle',
                  onTap: () =>
                      Navigator.pop(sheetContext, _CircleCardMenuAction.leave),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _CircleCardMenuAction.open:
        await context.push(AppRoutes.circle(circle.id));
        if (context.mounted) await context.read<CirclesCubit>().load();
      case _CircleCardMenuAction.leave:
        final confirmed = await MomentDialog.confirm(
          context,
          title: 'Leave circle?',
          message: 'You will no longer see moments shared to this circle.',
          confirmLabel: 'Leave',
        );
        if (confirmed != true || !context.mounted) return;
        final result = await sl<CircleRepository>().leaveCircle(
          circleId: circle.id,
        );
        if (!context.mounted) return;
        if (result is Success) {
          await context.read<CirclesCubit>().load();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.failureOrNull?.message ?? 'Could not leave circle.',
              ),
            ),
          );
        }
      case _CircleCardMenuAction.delete:
        final confirmed = await MomentDialog.confirm(
          context,
          title: 'Delete "${circle.name}"?',
          message:
              'This permanently removes the circle for everyone. This cannot be undone.',
          confirmLabel: 'Delete',
        );
        if (confirmed != true || !context.mounted) return;
        final result = await sl<CircleRepository>().deleteCircle(
          circleId: circle.id,
        );
        if (!context.mounted) return;
        if (result is Success) {
          await context.read<CirclesCubit>().load();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.failureOrNull?.message ?? 'Could not delete circle.',
              ),
            ),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.status == CirclesStatus.loading &&
        widget.state.circles.isEmpty) {
      return const _CirclesShimmer();
    }

    if (widget.state.status == CirclesStatus.failure &&
        widget.state.circles.isEmpty) {
      return MomentErrorState(
        message: widget.state.errorMessage ?? 'Could not load circles.',
        actionLabel: 'Retry',
        onAction: () => context.read<CirclesCubit>().load(),
      );
    }

    final circles = _filteredCircles;
    final state = widget.state;

    return RefreshIndicator(
      color: AppColors.violet,
      onRefresh: () => context.read<CirclesCubit>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding.copyWith(top: AppSpacing.lg, bottom: 120),
        children: [
          _CirclesHeader(
            circleCount: state.circles.length,
            peopleCount: state.totalPeople,
            onCreate: () => widget.onCreate(null),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: DarkSearchField(
                  controller: _searchController,
                  hint: 'Search circles',
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              SizedBox(width: 8),
              Material(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _showFilterSheet,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppColors.textTertiaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          if (circles.isEmpty && _query.isEmpty)
            ..._starterCards(widget.onCreate)
          else if (circles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'No circles match your search.',
                style: SettingsType.body(AppColors.textTertiaryDark),
              ),
            )
          else
            ...circles.map(
              (circle) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CircleCard(
                  circle: circle,
                  activity: state.activityByCircleId[circle.id],
                  members: state.membersByCircleId[circle.id] ?? const [],
                  onTap: () async {
                    await context.push(AppRoutes.circle(circle.id));
                    if (context.mounted) {
                      await context.read<CirclesCubit>().load();
                    }
                  },
                  onMore: () => _showCircleCardMenu(context, circle),
                ),
              ),
            ),
          SizedBox(height: AppSpacing.sm),
          if (widget.state.circles.isEmpty)
            _CreateCircleCta(onTap: () => widget.onCreate(null)),
        ],
      ),
    );
  }

  List<Widget> _starterCards(ValueChanged<CircleType?> onCreate) {
    return [
      for (final type in _starterTypes)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _CircleCard(
            circle: null,
            emoji: type.defaultEmoji,
            title: type.label,
            subtitle: 'Create circle',
            onTap: () => onCreate(type),
          ),
        ),
    ];
  }

  static const _starterTypes = [
    CircleType.us,
    CircleType.college,
    CircleType.family,
    CircleType.squad,
  ];
}

class _CirclesHeader extends StatelessWidget {
  const _CirclesHeader({
    required this.circleCount,
    required this.peopleCount,
    required this.onCreate,
  });

  final int circleCount;
  final int peopleCount;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: SettingsType.body(AppColors.textPrimaryDark).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: 'Your '),
                    TextSpan(
                      text: 'Circles',
                      style: SettingsType.body(AppColors.violet).copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3),
              Text(
                circleCount == 0
                    ? 'Start your first circle'
                    : '$circleCount ${circleCount == 1 ? 'circle' : 'circles'} · $peopleCount ${peopleCount == 1 ? 'person' : 'people'}',
                style: SettingsType.caption(AppColors.textTertiaryDark),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: AppColors.bloomGradient,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCreate,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Create',
                      style: SettingsType.caption(Colors.white).copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({
    required this.onTap,
    this.onMore,
    this.circle,
    this.activity,
    this.members = const [],
    this.emoji,
    this.title,
    this.subtitle,
  });

  final Circle? circle;
  final CircleActivitySummary? activity;
  final List<CircleMember> members;
  final String? emoji;
  final String? title;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title ?? circle!.name;
    final memberCount = circle?.memberCount ?? members.length;
    final momentCount = activity?.momentCount ?? 0;

    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (circle != null)
                CircleIcon(circle: circle!, size: 48, radius: 14)
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji ?? '✨',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SettingsType.body(AppColors.textPrimaryDark)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 3),
                    if (circle != null)
                      Text.rich(
                        TextSpan(
                          style: SettingsType.caption(
                            AppColors.textTertiaryDark,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${memberCount == 1 ? '1 member' : '$memberCount members'} · ',
                            ),
                            TextSpan(
                              text:
                                  '$momentCount ${momentCount == 1 ? 'moment' : 'moments'}',
                              style: TextStyle(color: AppColors.violet),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        subtitle ?? '',
                        style: SettingsType.caption(
                          AppColors.textTertiaryDark,
                        ),
                      ),
                    if (circle != null &&
                        activity?.latestActivityAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last moment · ${relativeTimeAgo(activity!.latestActivityAt!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SettingsType.caption(
                          AppColors.textTertiaryDark,
                        ),
                      ),
                    ],
                    if (circle != null && members.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      CircleMemberAvatarStack(
                        circleId: circle!.id,
                        members: members,
                      ),
                    ],
                  ],
                ),
              ),
              if (circle != null) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (activity?.latestImageUrl != null)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: MomentCachedImage(
                              imageUrl: activity!.latestImageUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (momentCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.violet,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  momentCount > 9 ? '9+' : '$momentCount',
                                  style:
                                      SettingsType.caption(Colors.white).copyWith(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    if (onMore != null)
                      IconButton(
                        onPressed: onMore,
                      icon: const Icon(Icons.more_horiz_rounded),
                      color: AppColors.textTertiaryDark,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: 'Circle options',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _CircleCardMenuAction { open, leave, delete }

class _CircleCardMenuTile extends StatelessWidget {
  const _CircleCardMenuTile({
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
    final color = destructive ? AppColors.errorDark : AppColors.textPrimaryDark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: SettingsType.body(color).copyWith(fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: onTap,
      title: Text(
        label,
        style: SettingsType.body(
          selected ? AppColors.violet : AppColors.textPrimaryDark,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, size: 18, color: AppColors.violet)
          : null,
    );
  }
}

class _CreateCircleCta extends StatelessWidget {
  const _CreateCircleCta({required this.onTap});

  final VoidCallback onTap;

  static const _assetPath = 'assets/images/circles_create_illustration.png';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: DashedBorder(
          color: AppColors.violet.withValues(alpha: 0.55),
          radius: 18,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.violet.withValues(alpha: 0.06),
            ),
            child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.violet.withValues(alpha: 0.35),
                  ),
                  color: AppColors.violet.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppColors.violet,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create a circle',
                      style: SettingsType.body(AppColors.textPrimaryDark)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Bring people together',
                      style: SettingsType.caption(
                        AppColors.textTertiaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  _assetPath,
                  width: 72,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CirclesShimmer extends StatelessWidget {
  const _CirclesShimmer();

  @override
  Widget build(BuildContext context) {
    return const MomentShimmer(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MomentShimmerBone(width: 120, height: 14, radius: 7),
            SizedBox(height: 6),
            MomentShimmerBone(width: 96, height: 10, radius: 5),
            SizedBox(height: AppSpacing.lg),
            MomentShimmerBone(height: 44, radius: 14),
            SizedBox(height: AppSpacing.xl),
            MomentShimmerBone(height: 88, radius: 18),
            SizedBox(height: 10),
            MomentShimmerBone(height: 88, radius: 18),
            SizedBox(height: AppSpacing.lg),
            MomentShimmerBone(height: 72, radius: 18),
          ],
        ),
      ),
    );
  }
}
