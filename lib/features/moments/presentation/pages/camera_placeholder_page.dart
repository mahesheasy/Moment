import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/widgets/live_camera_host.dart';
import 'package:moment/features/prompts/domain/entities/camera_prompt_context.dart';

class CameraPlaceholderPage extends StatelessWidget {
  const CameraPlaceholderPage({this.promptContext, super.key});

  final CameraPromptContext? promptContext;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CameraCubit>(param1: promptContext)..initialize(),
      child: const _CameraCaptureView(),
    );
  }
}

class _CameraCaptureView extends StatelessWidget {
  const _CameraCaptureView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CameraCubit, CameraState>(
      listener: (context, state) {
        if (state.errorMessage != null &&
            state.status == CameraStatus.failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: LiveCameraHost(
        builder: (context, session) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                    ),
                    child: Row(
                      children: [
                        _RoundIconButton(
                          icon: AppIcons.close,
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.pop();
                            }
                          },
                        ),
                        const Spacer(),
                        _RoundIconButton(
                          icon: session.flashEnabled
                              ? AppIcons.flash
                              : AppIcons.flashOff,
                          onTap: session.toggleFlash,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: session.viewfinder,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _CaptureBar(
                    onGallery: session.pickGallery,
                    onCapture: session.capture,
                    onFlip: session.flip,
                    capturing: session.capturing,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _ModeSelector(),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CaptureBar extends StatelessWidget {
  const _CaptureBar({
    required this.onGallery,
    required this.onCapture,
    required this.onFlip,
    this.capturing = false,
  });

  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback onFlip;
  final bool capturing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _LabeledRoundButton(
            icon: AppIcons.gallery,
            label: 'Gallery',
            onTap: onGallery,
          ),
          GestureDetector(
            onTap: capturing ? null : onCapture,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
              ),
              child: capturing
                  ? const Padding(
                      padding: EdgeInsets.all(22),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          _LabeledRoundButton(
            icon: AppIcons.flip,
            label: 'Flip',
            onTap: onFlip,
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'PHOTO',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.photoPink,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            '·',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.textTertiaryDark),
          ),
        ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video is coming soon.')),
            );
          },
          child: Text(
            'VIDEO',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textTertiaryDark,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledRoundButton extends StatelessWidget {
  const _LabeledRoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
