import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_hero_tags.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/utils/camera_flow_navigation.dart';
import 'package:moment/features/moments/presentation/widgets/camera_chrome.dart';

class CameraSentPage extends StatelessWidget {
  const CameraSentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) exitCameraFlowToHome(context);
      },
      child: BlocBuilder<CameraCubit, CameraState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sent',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Center(child: _SuccessMark()),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Moment Sent!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SentToLine(state: state),
                    const Spacer(),
                    _DarkActionButton(
                      label: 'View Moment',
                      onTap: () {
                        final id = state.sentMomentId;
                        if (id == null) {
                          exitCameraFlowToHome(context);
                          return;
                        }
                        exitCameraFlowToMoment(context, id);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DarkActionButton(
                      label: 'Back to Home',
                      onTap: () => exitCameraFlowToHome(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: MomentHeroTags.cameraSendSuccess,
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.85 + (animation.value * 0.15),
              child: child,
            );
          },
          child: toHeroContext.widget,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.violet,
                AppColors.sendCoral,
                AppColors.nextPurple,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(AppIcons.check, color: Colors.white, size: 64),
        ),
      ),
    );
  }
}

class _SentToLine extends StatelessWidget {
  const _SentToLine({required this.state});

  final CameraState state;

  @override
  Widget build(BuildContext context) {
    final avatars = <Widget>[];
    for (final circle in state.circles) {
      if (!state.selectedCircleIds.contains(circle.id)) continue;
      avatars.add(
        CircleAvatar(
          radius: 12,
          backgroundColor: circleAccentColor(
            circle.type,
          ).withValues(alpha: 0.3),
          child: Text(
            circle.displayEmoji,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    }
    for (final friend in state.friends) {
      if (!state.selectedRecipientIds.contains(friend.profile.id)) continue;
      avatars.add(
        MomentAvatar(
          name: friend.profile.displayName,
          imageUrl: friend.profile.avatarUrl,
          size: 24,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (avatars.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: SizedBox(
              width: 12.0 + (avatars.length.clamp(1, 3) * 16),
              height: 24,
              child: Stack(
                children: [
                  for (var i = 0; i < avatars.length && i < 3; i++)
                    Positioned(left: i * 16.0, child: avatars[i]),
                ],
              ),
            ),
          ),
        Flexible(
          child: Text(
            state.sentToLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkActionButton extends StatelessWidget {
  const _DarkActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevatedDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 54,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
