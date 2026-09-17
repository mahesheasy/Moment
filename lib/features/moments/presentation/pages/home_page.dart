import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/navigation/memories_overlay_controller.dart';
import 'package:moment/core/realtime/moment_realtime_subscriber.dart';
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
import 'package:moment/features/moments/presentation/widgets/live_camera_host.dart';
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
      sl<MomentRealtimeSubscriber>().listen((_) {
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
        BlocProvider(create: (_) => sl<CameraCubit>()..initialize()),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  var _upwardDrag = 0.0;

  void _openHistory(BuildContext context) {
    final home = context.read<HomeCubit>();
    final profile = context.read<ProfileCubit>();
    final friends = context.read<FriendsCubit>();
    final pings = context.read<PingsCubit>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: home),
            BlocProvider.value(value: profile),
            BlocProvider.value(value: friends),
            BlocProvider.value(value: pings),
          ],
          child: const _HistorySheet(),
        );
      },
    );
  }

  void _openMemories() {
    sl<MemoriesOverlayController>().open();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: Colors.black,
      child: BlocListener<HomeCubit, HomeState>(
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
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy < 0) {
              _upwardDrag += details.delta.dy;
              if (_upwardDrag < -72) {
                _upwardDrag = 0;
                _openMemories();
              }
            }
          },
          onVerticalDragEnd: (_) => _upwardDrag = 0,
          child: LiveCameraHost(
          pauseWhenCovered: true,
          builder: (context, session) {
            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const _HomeTopBar(),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          session.viewfinder,
                          Positioned(
                            top: 12,
                            left: 12,
                            child: _FlashChip(
                              enabled: session.flashEnabled,
                              onTap: session.toggleFlash,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _HomeCaptureBar(
                    capturing: session.capturing,
                    previewBytes: context.watch<CameraCubit>().state.imageBytes,
                    onGallery: session.pickGallery,
                    onCapture: session.capture,
                    onFlip: session.flip,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _HistoryHandle(onTap: () => _openHistory(context)),
                  SizedBox(height: 16 + bottomInset),
                ],
              ),
            );
          },
        ),
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          _ProfileCircleButton(),
          Spacer(),
          _FriendsPill(),
          Spacer(),
          _MessagesButton(),
        ],
      ),
    );
  }
}

class _ProfileCircleButton extends StatelessWidget {
  const _ProfileCircleButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final profile = state.profile;
        return GestureDetector(
          onTap: () => context.go(AppRoutes.profile),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A2A2A),
              border: Border.all(color: Colors.white24),
            ),
            clipBehavior: Clip.antiAlias,
            child: profile == null
                ? const Icon(AppIcons.profile, color: Colors.white, size: 22)
                : MomentAvatar(
                    name: profile.displayName,
                    imageUrl: profile.avatarUrl,
                    size: 42,
                  ),
          ),
        );
      },
    );
  }
}

class _FriendsPill extends StatelessWidget {
  const _FriendsPill();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsCubit, FriendsState>(
      builder: (context, state) {
        final count = state.friends.length;

        return GestureDetector(
          onTap: () => context.push(AppRoutes.friends),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.circlesFilled, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Friends',
                  style: SettingsType.title(
                    Colors.white,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: SettingsType.title(
                    Colors.white.withValues(alpha: 0.55),
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessagesButton extends StatelessWidget {
  const _MessagesButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsCubit, FriendsState>(
      builder: (context, state) {
        final badge = state.pendingCount > 0;
        return GestureDetector(
          onTap: () => context.push(AppRoutes.notifications),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.notifications,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (badge)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 8, height: 8),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FlashChip extends StatelessWidget {
  const _FlashChip({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          enabled ? AppIcons.flash : AppIcons.flashOff,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _HomeCaptureBar extends StatelessWidget {
  const _HomeCaptureBar({
    required this.capturing,
    required this.onGallery,
    required this.onCapture,
    required this.onFlip,
    this.previewBytes,
  });

  final bool capturing;
  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback onFlip;
  final Uint8List? previewBytes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onGallery,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52,
                height: 52,
                child: previewBytes == null
                    ? const ColoredBox(
                        color: Color(0xFF2A2A2A),
                        child: Center(
                          child: _HomeBarIcon(
                            asset: 'assets/images/home_gallery_icon.png',
                            size: 34,
                          ),
                        ),
                      )
                    : Image.memory(previewBytes!, fit: BoxFit.cover),
              ),
            ),
          ),
          GestureDetector(
            onTap: capturing ? null : onCapture,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.sendCoral, width: 4),
              ),
              child: Center(
                child: capturing
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onFlip,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 52,
                height: 52,
                child: ColoredBox(
                  color: Color(0xFF2A2A2A),
                  child: Center(
                    child: _HomeBarIcon(
                      asset: 'assets/images/home_camera_icon.png',
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBarIcon extends StatelessWidget {
  const _HomeBarIcon({required this.asset, this.size = 24});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        asset.contains('gallery') ? AppIcons.gallery : AppIcons.flip,
        color: Colors.white,
        size: size,
      ),
    );
  }
}

class _HistoryHandle extends StatelessWidget {
  const _HistoryHandle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0).abs() > 240) onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'History',
              style: SettingsType.title(
                Colors.white,
              ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySheet extends StatelessWidget {
  const _HistorySheet();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.92;

    return SizedBox(
      height: height,
      child: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _HistoryHeader(),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.violet,
                    onRefresh: () => context.read<HomeCubit>().load(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                        40,
                      ),
                      children: [
                        switch (state.status) {
                          HomeStatus.loading ||
                          HomeStatus.initial => const _HeroPlaceholder(),
                          HomeStatus.failure => MomentErrorState(
                            message:
                                state.errorMessage ?? 'Could not load home.',
                            actionLabel: 'Retry',
                            onAction: () => context.read<HomeCubit>().load(),
                          ),
                          HomeStatus.empty => const _EmptyMomentCard(),
                          HomeStatus.loaded => const _HeroStoryCard(),
                        },
                        const SizedBox(height: AppSpacing.xxxl),
                        const HomePingsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        final profile = profileState.profile;
        final firstName = firstNameOf(profile?.displayName);
        final greeting = timeSensitiveGreeting();

        return Row(
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
                    const SizedBox(height: 2),
                    Text(
                      '$firstName 👋',
                      style: SettingsType.body(
                        AppColors.violet,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(AppIcons.close, color: Colors.white, size: 20),
            ),
          ],
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
      onButtonTap: () {
        Navigator.pop(context);
      },
      onTap: () {
        Navigator.pop(context);
      },
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
            const SizedBox(height: AppSpacing.md),
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
