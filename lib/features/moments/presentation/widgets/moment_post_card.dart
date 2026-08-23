import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/core/widgets/moment_action_bar.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/circles/presentation/circle_style.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class MomentPostCard extends StatelessWidget {
  const MomentPostCard({
    required this.moment,
    required this.onOpen,
    required this.onPing,
    required this.onReact,
    required this.onCamera,
    this.circle,
    this.members = const [],
    this.reacted = false,
    this.storyCount = 1,
    this.storyIndex = 0,
    this.onPhotoTap,
    super.key,
  });

  final Moment moment;
  final Circle? circle;
  final List<UserProfile> members;
  final bool reacted;
  final int storyCount;
  final int storyIndex;
  final VoidCallback onOpen;
  final VoidCallback onPing;
  final VoidCallback onReact;
  final VoidCallback onCamera;
  final void Function(bool tapLeft)? onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final isCircle = circle != null;
    final title = isCircle ? circle!.name : moment.sender.displayName;
    final accent = isCircle
        ? CircleStyle.accent(circle!.type)
        : AppColors.violet;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderDark),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onOpen,
            child: Row(
              children: [
                if (isCircle && members.length >= 2)
                  OverlappingAvatars(
                    imageUrls: members.map((m) => m.avatarUrl).toList(),
                    names: members.map((m) => m.displayName).toList(),
                    ringColors: [accent, CircleStyle.iconWell(circle!.type)],
                  )
                else if (isCircle)
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      circle!.displayEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  )
                else
                  MomentAvatar(
                    name: moment.sender.displayName,
                    imageUrl: moment.sender.avatarUrl,
                    size: 40,
                  ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        isCircle
                            ? '${moment.sender.displayName} · ${relativeTimeAgo(moment.createdAt)}'
                            : relativeTimeAgo(moment.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: accent.withValues(alpha: 0.85),
                  size: 22,
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    child: moment.imageUrl == null
                        ? ColoredBox(
                            key: ValueKey('empty'),
                            color: AppColors.photoPlaceholderDark,
                          )
                        : Image.network(
                            moment.imageUrl!,
                            key: ValueKey(moment.id),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                  ),
                  if (storyCount > 1)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Row(
                        children: [
                          for (var i = 0; i < storyCount; i++) ...[
                            if (i > 0) SizedBox(width: 4),
                            Expanded(
                              child: Container(
                                height: 2.5,
                                decoration: BoxDecoration(
                                  color: i <= storyIndex
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) {
                            if (onPhotoTap != null && storyCount > 1) {
                              onPhotoTap!(
                                details.localPosition.dx <
                                    constraints.maxWidth * 0.32,
                              );
                            } else {
                              onOpen();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          MomentActionBar(
            reacted: reacted,
            onPing: onPing,
            onReact: onReact,
            onCamera: onCamera,
          ),
        ],
      ),
    );
  }
}
