import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_breakpoints.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_cached_image.dart';
import 'package:moment/core/widgets/moment_hero_tags.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/widgets/reaction_bar.dart';
import 'package:moment/features/moments/presentation/widgets/reaction_picker_sheet.dart';

class MomentDetailPage extends StatelessWidget {
  const MomentDetailPage({required this.momentId, super.key});

  final String momentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MomentDetailCubit>(param1: momentId)..load(),
      child: _MomentDetailView(momentId: momentId),
    );
  }
}

class _MomentDetailView extends StatefulWidget {
  const _MomentDetailView({required this.momentId});

  final String momentId;

  @override
  State<_MomentDetailView> createState() => _MomentDetailViewState();
}

class _MomentDetailViewState extends State<_MomentDetailView> {
  var _handledWidgetAction = false;

  @override
  Widget build(BuildContext context) {
    final maxWidth = AppBreakpoints.contentMaxWidth(context);
    final padding = AppBreakpoints.pagePadding(context);
    final widgetAction = GoRouterState.of(
      context,
    ).uri.queryParameters['widgetAction'];

    return BlocConsumer<MomentDetailCubit, MomentDetailState>(
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
        if (!_handledWidgetAction &&
            widgetAction != null &&
            state.status == MomentDetailStatus.loaded &&
            state.moment != null) {
          _handledWidgetAction = true;
          final cubit = context.read<MomentDetailCubit>();
          if (widgetAction == 'ping') {
            if (state.moment!.sender.id != sl<AuthRepository>().currentUserId) {
              unawaited(cubit.pingSender());
            }
          } else if (widgetAction == 'react') {
            unawaited(
              ReactionPickerSheet.show(context).then((type) {
                if (type != null && context.mounted) {
                  unawaited(cubit.react(type));
                }
              }),
            );
          }
        }
      },
      builder: (context, state) {
        return MomentScaffold(
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SizedBox.expand(
                  child: _bodyFor(context, state, padding),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bodyFor(
    BuildContext context,
    MomentDetailState state,
    EdgeInsets padding,
  ) {
    if (state.status == MomentDetailStatus.loading ||
        state.status == MomentDetailStatus.initial) {
      return _MomentDetailShimmer(padding: padding);
    }

    if (state.status == MomentDetailStatus.failure || state.moment == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: padding.copyWith(top: AppSpacing.sm),
            child: const _DetailBackButton(),
          ),
          Expanded(
            child: MomentErrorState(
              message: state.errorMessage ?? 'Could not load moment.',
              actionLabel: 'Retry',
              onAction: () => context.read<MomentDetailCubit>().load(),
            ),
          ),
        ],
      );
    }

    final moment = state.moment!;
    final caption = moment.caption?.trim();
    final heroScope =
        GoRouterState.of(context).uri.queryParameters['heroScope'] ??
        MomentHeroTags.scopeHome;

    return Padding(
      padding: padding.copyWith(top: AppSpacing.sm, bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _DetailBackButton(),
              SizedBox(width: AppSpacing.md),
              MomentAvatar(
                name: moment.sender.displayName,
                imageUrl: moment.sender.avatarUrl,
                size: 42,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment.sender.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      relativeTimeAgo(moment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          Expanded(
            child: Hero(
              tag: MomentHeroTags.photo(
                widget.momentId,
                scope: heroScope,
              ),
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: AppRadius.xxxlAll,
                  child: moment.imageUrl == null
                    ? ColoredBox(
                        color: AppColors.photoPlaceholderDark,
                        child: Center(
                          child: Icon(
                            Icons.photo_outlined,
                            size: 48,
                            color: AppColors.textTertiaryDark,
                          ),
                        ),
                      )
                    : MomentCachedImage(
                        imageUrl: moment.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                ),
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty) ...[
            SizedBox(height: AppSpacing.lg),
            Text(
              caption,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondaryDark,
                height: 1.45,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.xl),
          ReactionBar(
            summary: state.reactions,
            onReact: () async {
              final type = await ReactionPickerSheet.show(context);
              if (type != null && context.mounted) {
                await context.read<MomentDetailCubit>().react(type);
              }
            },
            onPing: moment.sender.id == sl<AuthRepository>().currentUserId
                ? null
                : () => context.read<MomentDetailCubit>().pingSender(),
          ),
        ],
      ),
    );
  }
}

class _DetailBackButton extends StatelessWidget {
  const _DetailBackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(AppRoutes.home);
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedDark,
            shape: BoxShape.circle,
          ),
          child: Icon(
            AppIcons.back,
            size: 18,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
    );
  }
}

class _MomentDetailShimmer extends StatelessWidget {
  const _MomentDetailShimmer({required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return MomentShimmer(
      child: Padding(
        padding: padding.copyWith(top: AppSpacing.sm, bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MomentShimmerBone(
                  width: 44,
                  height: 44,
                  shape: BoxShape.circle,
                ),
                SizedBox(width: AppSpacing.md),
                MomentShimmerBone(
                  width: 42,
                  height: 42,
                  shape: BoxShape.circle,
                ),
                SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MomentShimmerBone(width: 120, height: 16, radius: 8),
                    SizedBox(height: AppSpacing.sm),
                    MomentShimmerBone(width: 72, height: 12, radius: 6),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            Expanded(child: MomentShimmerBone(radius: 32)),
            SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                MomentShimmerBone(width: 88, height: 44, radius: 22),
                SizedBox(width: AppSpacing.md),
                MomentShimmerBone(width: 96, height: 44, radius: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
