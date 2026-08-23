import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/widgets/camera_chrome.dart';

class CameraSentPage extends StatelessWidget {
  const CameraSentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: BlocBuilder<CameraCubit, CameraState>(
        builder: (context, state) {
          return Scaffold(
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
                    Spacer(),
                    Center(child: _SuccessMark()),
                    SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Moment Sent!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    _SentToLine(state: state),
                    Spacer(),
                    _DarkActionButton(
                      label: 'View Moment',
                      onTap: () {
                        final id = state.sentMomentId;
                        if (id == null) {
                          context.go(AppRoutes.home);
                          return;
                        }
                        context.go(AppRoutes.moment(id));
                      },
                    ),
                    SizedBox(height: AppSpacing.md),
                    _DarkActionButton(
                      label: 'Back to Home',
                      onTap: () => context.go(AppRoutes.home),
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
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.violet, AppColors.sendCoral, AppColors.nextPurple],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(AppIcons.check, color: Colors.white, size: 64),
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
