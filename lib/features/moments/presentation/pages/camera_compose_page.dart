import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/utils/camera_flow_navigation.dart';
import 'package:moment/features/moments/presentation/widgets/camera_captions_sheet.dart';
import 'package:moment/features/moments/presentation/widgets/camera_chrome.dart';

class CameraComposePage extends StatefulWidget {
  const CameraComposePage({super.key});

  @override
  State<CameraComposePage> createState() => _CameraComposePageState();
}

class _CameraComposePageState extends State<CameraComposePage> {
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
    if (!cubit.state.hasSelection &&
        !cubit.state.isPromptMode &&
        (cubit.state.friends.isNotEmpty || cubit.state.circles.isNotEmpty)) {
      cubit.selectAllRecipients();
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CameraCubit, CameraState>(
      listenWhen: (prev, next) =>
          prev.status != next.status || prev.errorMessage != next.errorMessage,
      listener: (context, state) {
        if (state.status == CameraStatus.success) {
          final messenger = ScaffoldMessenger.of(context);
          final label = state.sentToLabel;
          exitCameraFlowToHome(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            messenger.showSnackBar(SnackBar(content: Text(label)));
          });
          return;
        }
        if (state.errorMessage != null &&
            state.status != CameraStatus.success &&
            state.status != CameraStatus.uploading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final uploading = state.status == CameraStatus.uploading;
        final cubit = context.read<CameraCubit>();
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
                        onPressed: uploading ? null : () => Navigator.pop(context),
                        icon: const Icon(AppIcons.back, color: Colors.white, size: 20),
                      ),
                      Expanded(
                        child: Text(
                          'Preview',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  TextField(
                    controller: _captionController,
                    enabled: !uploading,
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: cubit.setCaption,
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadius.xxxlAll,
                      child: bytes == null
                          ? MomentShimmer(
                              child: ColoredBox(color: AppColors.photoPlaceholderDark),
                            )
                          : Image.memory(bytes, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DetailsButton(
                    enabled: !uploading,
                    activeCount: _activeDetailCount(state),
                    onTap: () => showCameraCaptionsSheet(
                      context,
                      reviewController: _reviewController,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Send to',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiaryDark,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RecipientStrip(state: state, enabled: !uploading),
                  const SizedBox(height: AppSpacing.lg),
                  CameraGradientButton(
                    label: uploading
                        ? 'Sending…'
                        : state.hasSelection
                        ? 'Send moment'
                        : 'Choose someone',
                    isLoading: uploading,
                    onPressed: uploading || !state.hasSelection ? null : cubit.send,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _activeDetailCount(CameraState state) {
    var count = 0;
    if (state.reviewRating > 0) count++;
    if (state.includeLocation) count++;
    if (state.includeWeather) count++;
    if (state.includeTime) count++;
    if (state.includeStreak) count++;
    count += state.decorations.length;
    return count;
  }
}

class _DetailsButton extends StatelessWidget {
  const _DetailsButton({
    required this.enabled,
    required this.activeCount,
    required this.onTap,
  });

  final bool enabled;
  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.violet, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  activeCount > 0
                      ? 'Stickers & details · $activeCount added'
                      : 'Stickers & details',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                AppIcons.chevronRight,
                color: AppColors.textTertiaryDark,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipientStrip extends StatelessWidget {
  const _RecipientStrip({required this.state, required this.enabled});

  final CameraState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingRecipients) {
      return const SizedBox(
        height: 72,
        child: Center(child: MomentLoading()),
      );
    }

    final cubit = context.read<CameraCubit>();

    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: 'All',
            selected: state.isAllSelected,
            onTap: enabled ? cubit.selectAllRecipients : null,
            child: Icon(
              AppIcons.circles,
              size: 20,
              color: state.isAllSelected ? AppColors.violet : Colors.white70,
            ),
          ),
          for (final circle in state.circles)
            _Chip(
              label: circle.name,
              selected: !state.isAllSelected &&
                  state.selectedCircleIds.contains(circle.id),
              onTap: enabled ? () => cubit.selectOnlyCircle(circle.id) : null,
              child: Text(circle.displayEmoji, style: const TextStyle(fontSize: 18)),
            ),
          if (state.currentUserId != null)
            _Chip(
              label: 'Me',
              selected: !state.isAllSelected &&
                  state.selectedRecipientIds.length == 1 &&
                  state.selectedRecipientIds.contains(state.currentUserId),
              onTap: enabled
                  ? () => cubit.selectOnlyRecipient(state.currentUserId!)
                  : null,
              child: MomentAvatar(name: 'Me', size: 40),
            ),
          for (final friend in state.friends)
            _Chip(
              label: _short(friend.profile.displayName),
              selected: !state.isAllSelected &&
                  state.selectedRecipientIds.length == 1 &&
                  state.selectedRecipientIds.contains(friend.profile.id),
              onTap: enabled
                  ? () => cubit.selectOnlyRecipient(friend.profile.id)
                  : null,
              child: MomentAvatar(
                name: friend.profile.displayName,
                imageUrl: friend.profile.avatarUrl,
                size: 40,
              ),
            ),
        ],
      ),
    );
  }

  static String _short(String name) =>
      name.length <= 8 ? name : '${name.substring(0, 7)}…';
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.child,
    this.onTap,
  });

  final String label;
  final bool selected;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceDark,
                border: Border.all(
                  color: selected ? AppColors.violet : AppColors.borderDark,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(child: child),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 52,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? AppColors.violet : AppColors.textTertiaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
