import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/pages/camera_sent_page.dart';
import 'package:moment/features/moments/presentation/widgets/camera_chrome.dart';

class CameraSendToPage extends StatelessWidget {
  const CameraSendToPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CameraCubit, CameraState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.status == CameraStatus.success) {
          final cubit = context.read<CameraCubit>();
          final navigator = Navigator.of(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: const CameraSentPage(),
                ),
              ),
            );
          });
        }
        if (state.errorMessage != null &&
            state.status != CameraStatus.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        final uploading = state.status == CameraStatus.uploading;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: uploading
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: Icon(
                          AppIcons.back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Send To',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: TextField(
                    enabled: !uploading,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: AppColors.violet,
                    onChanged: context.read<CameraCubit>().setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search people or circles',
                      hintStyle: TextStyle(
                        color: AppColors.textTertiaryDark,
                      ),
                      prefixIcon: Icon(
                        AppIcons.search,
                        color: AppColors.textTertiaryDark,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: state.isLoadingRecipients
                      ? const _SendToShimmer()
                      : _RecipientList(state: state, enabled: !uploading),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  child: CameraGradientButton(
                    label: uploading
                        ? 'Sending…'
                        : state.hasSelection
                        ? 'Send to ${state.selectedRecipientIds.length + state.selectedCircleIds.length}'
                        : 'Choose someone',
                    isLoading: uploading,
                    onPressed: uploading
                        ? null
                        : () => context.read<CameraCubit>().send(),
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

class _RecipientList extends StatelessWidget {
  const _RecipientList({required this.state, required this.enabled});

  final CameraState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final circles = state.filteredCircles;
    final friends = state.filteredFriends;
    final query = state.searchQuery.trim().toLowerCase();
    final showMe =
        state.currentUserId != null &&
        (query.isEmpty || query.contains('me') || query.contains('you'));

    Future<void> openFriends() async {
      await context.push(AppRoutes.friends);
      if (context.mounted) {
        await context.read<CameraCubit>().reloadRecipients();
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      children: [
        if (circles.isNotEmpty) ...[
          const _SectionLabel('CIRCLES'),
          for (final circle in circles)
            _CircleTile(
              circle: circle,
              selected: state.selectedCircleIds.contains(circle.id),
              onTap: enabled
                  ? () => context.read<CameraCubit>().toggleCircle(circle.id)
                  : null,
            ),
          SizedBox(height: AppSpacing.lg),
        ],
        const _SectionLabel('CLOSE FRIENDS'),
        if (showMe && state.currentUserId != null)
          _PersonTile(
            name: 'Me',
            subtitle: 'Keep this for yourself',
            selected: state.selectedRecipientIds.contains(state.currentUserId),
            onTap: enabled
                ? () => context.read<CameraCubit>().toggleRecipient(
                    state.currentUserId!,
                  )
                : null,
          ),
        for (final friend in friends)
          _PersonTile(
            name: friend.profile.displayName,
            imageUrl: friend.profile.avatarUrl,
            selected: state.selectedRecipientIds.contains(friend.profile.id),
            onTap: enabled
                ? () => context.read<CameraCubit>().toggleRecipient(
                    friend.profile.id,
                  )
                : null,
          ),
        if (friends.isEmpty) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            'Add a friend to send this to someone specific.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
        SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: MomentButton(
            label: 'Add friends',
            variant: MomentButtonVariant.secondary,
            expanded: false,
            onPressed: enabled ? openFriends : null,
          ),
        ),
        SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textTertiaryDark,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CircleTile extends StatelessWidget {
  const _CircleTile({
    required this.circle,
    required this.selected,
    required this.onTap,
  });

  final Circle circle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = circleAccentColor(circle.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.violet.withValues(alpha: 0.14)
            : AppColors.surfaceDark,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.22),
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: Center(
                    child: Text(
                      circle.displayEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        circle.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '${circle.memberCount} ${circle.memberCount == 1 ? 'member' : 'members'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                CameraSelectionCheck(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.name,
    required this.selected,
    required this.onTap,
    this.imageUrl,
    this.subtitle,
  });

  final String name;
  final String? imageUrl;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.violet.withValues(alpha: 0.14)
            : AppColors.surfaceDark,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                MomentAvatar(name: name, imageUrl: imageUrl, size: 48),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textTertiaryDark),
                        ),
                    ],
                  ),
                ),
                CameraSelectionCheck(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SendToShimmer extends StatelessWidget {
  const _SendToShimmer();

  @override
  Widget build(BuildContext context) {
    return MomentShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        children: const [
          SizedBox(height: AppSpacing.md),
          MomentShimmerBone(width: 72, height: 12, radius: 6),
          SizedBox(height: AppSpacing.lg),
          _ShimmerRow(),
          _ShimmerRow(),
          SizedBox(height: AppSpacing.xl),
          MomentShimmerBone(width: 110, height: 12, radius: 6),
          SizedBox(height: AppSpacing.lg),
          _ShimmerRow(circle: true),
          _ShimmerRow(circle: true),
          _ShimmerRow(circle: true),
        ],
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow({this.circle = false});

  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          MomentShimmerBone(
            width: 48,
            height: 48,
            radius: circle ? 24 : 12,
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MomentShimmerBone(width: 120, height: 14, radius: 7),
                SizedBox(height: AppSpacing.sm),
                MomentShimmerBone(width: 72, height: 10, radius: 5),
              ],
            ),
          ),
          const MomentShimmerBone(
            width: 26,
            height: 26,
            shape: BoxShape.circle,
          ),
        ],
      ),
    );
  }
}
