import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_cached_image.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/circles/presentation/cubit/circle_detail_cubit.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class CircleMomentsPage extends StatelessWidget {
  const CircleMomentsPage({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CircleDetailCubit>(param1: circleId)..load(),
      child: _CircleMomentsView(circleId: circleId),
    );
  }
}

class _CircleMomentsView extends StatelessWidget {
  const _CircleMomentsView({required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleDetailCubit, CircleDetailState>(
      builder: (context, state) {
        final circle = state.circle;
        final title = circle == null
            ? 'Moments together'
            : '${circle.emoji} ${circle.name}';

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundDark,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(AppIcons.back, size: 18),
            ),
            title: Text(
              title,
              style: SettingsType.title(Colors.white).copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: switch (state.status) {
            CircleDetailStatus.loading when circle == null =>
              const Center(child: MomentLoading()),
            CircleDetailStatus.failure when circle == null =>
              MomentErrorState(
                message: state.errorMessage ?? 'Could not load moments.',
                actionLabel: 'Retry',
                onAction: () => context.read<CircleDetailCubit>().load(),
              ),
            _ => _MomentsBody(
                moments: state.moments,
                onOpenCamera: () => context.push(AppRoutes.cameraForCircle(circleId)),
              ),
          },
        );
      },
    );
  }
}

class _MomentsBody extends StatelessWidget {
  const _MomentsBody({
    required this.moments,
    required this.onOpenCamera,
  });

  final List<Moment> moments;
  final VoidCallback onOpenCamera;

  @override
  Widget build(BuildContext context) {
    if (moments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MomentEmptyState(
                message: 'No moments yet.\nShare a photo to this circle.',
              ),
              const SizedBox(height: 20),
              _PrimaryMomentButton(
                label: 'Open camera',
                onTap: onOpenCamera,
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              '${moments.length} ${moments.length == 1 ? 'moment' : 'moments'}',
              style: SettingsType.caption(AppColors.textTertiaryDark).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final moment = moments[index];
                return _MomentTile(moment: moment);
              },
              childCount: moments.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _MomentTile extends StatelessWidget {
  const _MomentTile({required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.moment(moment.id)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (moment.imageUrl == null)
            ColoredBox(color: AppColors.photoPlaceholderDark)
          else
            MomentCachedImage(imageUrl: moment.imageUrl!, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
                stops: const [0.55, 1],
              ),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Row(
              children: [
                MomentAvatar(
                  name: moment.sender.displayName,
                  imageUrl: moment.sender.avatarUrl,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    relativeTimeAgo(moment.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SettingsType.caption(Colors.white).copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryMomentButton extends StatelessWidget {
  const _PrimaryMomentButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppColors.bloomGradient,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: SettingsType.body(Colors.white).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
