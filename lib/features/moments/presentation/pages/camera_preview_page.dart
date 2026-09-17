import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/pages/camera_send_to_page.dart';
import 'package:moment/features/moments/presentation/widgets/camera_captions_sheet.dart';
import 'package:moment/features/moments/presentation/widgets/camera_chrome.dart';

class CameraPreviewPage extends StatefulWidget {
  const CameraPreviewPage({super.key});

  @override
  State<CameraPreviewPage> createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  late final TextEditingController _captionController;
  late final TextEditingController _reviewController;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<CameraCubit>();
    _captionController = TextEditingController(text: cubit.state.caption);
    _reviewController = TextEditingController(text: cubit.state.reviewText);
    if (cubit.state.timeLabel == null) {
      unawaited(cubit.loadMomentContext());
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _openDetails() {
    showCameraCaptionsSheet(
      context,
      reviewController: _reviewController,
    );
  }

  int _detailCount(CameraState state) {
    var count = 0;
    if (state.reviewRating > 0) count++;
    if (state.includeLocation) count++;
    if (state.includeWeather) count++;
    if (state.includeTime) count++;
    if (state.includeStreak) count++;
    count += state.decorations.length;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraCubit, CameraState>(
      builder: (context, state) {
        final bytes = state.imageBytes;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          AppIcons.back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Preview',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: _openDetails,
                        tooltip: 'Stickers',
                        icon: Icon(
                          Icons.auto_awesome_rounded,
                          color: _detailCount(state) > 0
                              ? AppColors.violet
                              : Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _captionController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: AppColors.violet,
                    decoration: InputDecoration(
                      hintText: 'Add a caption...',
                      hintStyle: TextStyle(color: AppColors.textTertiaryDark),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: context.read<CameraCubit>().setCaption,
                  ),
                  if (state.isPromptMode && state.promptText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        state.promptText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadius.xxxlAll,
                      child: bytes == null
                          ? MomentShimmer(
                              child: ColoredBox(
                                color: AppColors.photoPlaceholderDark,
                              ),
                            )
                          : Image.memory(bytes, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  CameraGradientButton(
                    label: 'Next',
                    onPressed: bytes == null
                        ? null
                        : () {
                            final cubit = context.read<CameraCubit>();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BlocProvider.value(
                                  value: cubit,
                                  child: const CameraSendToPage(),
                                ),
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
