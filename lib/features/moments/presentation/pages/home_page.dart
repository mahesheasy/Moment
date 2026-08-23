import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/realtime/moment_realtime_subscriber.dart';
import 'package:moment/core/theme/app_breakpoints.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/utils/greeting.dart';
import 'package:moment/core/widgets/empty_moments_card.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/friends/presentation/cubit/friends_cubit.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/cubit/pings_cubit.dart';
import 'package:moment/features/moments/presentation/widgets/home_pings_section.dart';
import 'package:moment/features/moments/presentation/widgets/reaction_picker_sheet.dart';
import 'package:moment/features/moments/presentation/widgets/tinder_moment_deck.dart';
import 'package:moment/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = sl<HomeCubit>()..load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      sl<MomentRealtimeSubscriber>().listen(() {
        if (mounted) _homeCubit.load();
      });
    });
  }

  @override
  void dispose() {
    _homeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeCubit),
        BlocProvider(create: (_) => sl<ProfileCubit>()..load()),
        BlocProvider(create: (_) => sl<FriendsCubit>()..load()),
        BlocProvider(create: (_) => sl<PingsCubit>()..load()),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final maxWidth = AppBreakpoints.contentMaxWidth(context);
    final padding = AppBreakpoints.pagePadding(context);

    return ColoredBox(
      color: AppColors.backgroundDark,
      child: BlocConsumer<HomeCubit, HomeState>(
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
          return SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: RefreshIndicator(
                  color: AppColors.violet,
                  onRefresh: () => context.read<HomeCubit>().load(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: padding.copyWith(top: AppSpacing.lg, bottom: 120),
                    children: [
                      const _HomeHeader(),
                      SizedBox(height: AppSpacing.xxl),
                      switch (state.status) {
                        HomeStatus.loading ||
                        HomeStatus.initial => const _HeroPlaceholder(),
                        HomeStatus.failure => MomentErrorState(
                          message: state.errorMessage ?? 'Could not load home.',
                          actionLabel: 'Retry',
                          onAction: () => context.read<HomeCubit>().load(),
                        ),
                        HomeStatus.empty => const _EmptyMomentCard(),
                        HomeStatus.loaded => const _HeroStoryCard(),
                      },
                      SizedBox(height: AppSpacing.xxxl),
                      const HomePingsSection(),
                    ],
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        final profile = profileState.profile;
        final firstName = firstNameOf(profile?.displayName);
        final greeting = timeSensitiveGreeting();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: SettingsType.caption(
                      AppColors.textSecondaryDark,
                    ).copyWith(fontWeight: FontWeight.w400),
                  ),
                  if (firstName.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      '$firstName 👋',
                      style: SettingsType.body(AppColors.violet).copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const _NotificationButton(),
            SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () => context.go(AppRoutes.profile),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  MomentAvatar(
                    name: profile?.displayName,
                    imageUrl: profile?.avatarUrl,
                    size: 36,
                    showBorder: true,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.backgroundDark,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsCubit, FriendsState>(
      builder: (context, state) {
        final badge = state.pendingCount > 0;
        return IconButton(
          onPressed: () => context.push(AppRoutes.notifications),
          tooltip: 'Friends',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                AppIcons.notifications,
                color: AppColors.textSecondaryDark,
                size: 20,
              ),
              if (badge)
                Positioned(
                  top: -1,
                  right: -1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(width: 7, height: 7),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const MomentShimmer(
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: MomentShimmerBone(
          width: double.infinity,
          height: double.infinity,
          radius: 22,
        ),
      ),
    );
  }
}

class _EmptyMomentCard extends StatelessWidget {
  const _EmptyMomentCard();

  @override
  Widget build(BuildContext context) {
    return EmptyMomentsCard(
      title: 'You\'re all caught up',
      subtitle: 'New moments land here. Viewed ones move to Memories.',
      buttonLabel: 'Capture a moment',
      onButtonTap: () => context.push(AppRoutes.camera),
      onTap: () => context.push(AppRoutes.camera),
    );
  }
}

class _HeroStoryCard extends StatefulWidget {
  const _HeroStoryCard();

  @override
  State<_HeroStoryCard> createState() => _HeroStoryCardState();
}

class _HeroStoryCardState extends State<_HeroStoryCard> {
  void _precacheNeighbors(HomeState state) {
    final stories = state.storyMoments;
    if (stories.length < 2) return;
    final nextIndex = state.storyIndex + 1;
    final previousIndex = state.storyIndex - 1;
    final neighbors = <Moment>[
      if (nextIndex < stories.length) stories[nextIndex],
      if (previousIndex >= 0) stories[previousIndex],
    ];
    for (final moment in neighbors) {
      final url = moment.imageUrl;
      if (url != null) {
        precacheImage(NetworkImage(url), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
          previous.storyIndex != current.storyIndex ||
          previous.moment?.id != current.moment?.id,
      listener: (context, state) => _precacheNeighbors(state),
      builder: (context, state) {
        final moment = state.moment;
        if (moment == null) return const SizedBox.shrink();
        final reaction = state.reactions?.myReaction;
        final cubit = context.read<HomeCubit>();
        final myId = context.watch<ProfileCubit>().state.profile?.id;
        final canPing = myId != null && myId != moment.sender.id;

        return Column(
          children: [
            TinderMomentDeck(
              moments: state.storyMoments.isEmpty
                  ? [moment]
                  : state.storyMoments,
              index: state.storyMoments.isEmpty
                  ? 0
                  : state.storyIndex.clamp(0, state.storyMoments.length - 1),
              reacted: reaction != null,
              reactionEmoji: reaction?.emoji ?? '😊',
              canPing: canPing,
              onNext: cubit.nextStory,
              onPrevious: cubit.previousStory,
              onOpen: () {
                final opened = moment;
                unawaited(cubit.markViewed(opened.id));
                context.push(AppRoutes.moment(opened.id));
              },
              onPing: cubit.pingSender,
              onReact: () async {
                final type = await ReactionPickerSheet.show(context);
                if (type != null && context.mounted) {
                  await cubit.react(type);
                }
              },
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              state.storyMoments.length > 1
                  ? '${state.storyMoments.length} unviewed  ·  swipe left when you\'ve seen this'
                  : 'Tap to open  ·  swipe left to archive',
              style: SettingsType.caption(AppColors.textTertiaryDark),
            ),
          ],
        );
      },
    );
  }
}
