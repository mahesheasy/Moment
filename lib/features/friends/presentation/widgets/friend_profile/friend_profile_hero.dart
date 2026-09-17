import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';
import 'package:moment/features/friends/presentation/theme/friend_profile_theme.dart';
import 'package:moment/features/friends/presentation/theme/friend_profile_typography.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'package:moment/features/profile/domain/presence_utils.dart';

class FriendProfileHero extends StatelessWidget {
  const FriendProfileHero({
    required this.profile,
    this.showOnlineStatus = false,
    super.key,
  });

  final UserProfile profile;
  final bool showOnlineStatus;

  @override
  Widget build(BuildContext context) {
    final bio = profile.bio?.trim();

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            _ProfileAvatarRing(profile: profile),
            if (showOnlineStatus)
              Positioned(
                bottom: -2,
                child: _OnlineStatusPill(profile: profile),
              ),
          ],
        ),
        SizedBox(height: showOnlineStatus ? AppSpacing.lg : AppSpacing.md),
        Text(
          profile.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: FriendProfileTextStyles.displayName,
        ),
        const SizedBox(height: 6),
        Text(
          '@${profile.username}',
          style: FriendProfileTextStyles.username,
        ),
        if (bio != null && bio.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            bio,
            textAlign: TextAlign.center,
            style: FriendProfileTextStyles.bio,
          ),
        ],
      ],
    );
  }
}

class _ProfileAvatarRing extends StatelessWidget {
  const _ProfileAvatarRing({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: FriendProfileTheme.avatarOuter,
      height: FriendProfileTheme.avatarOuter,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: FriendProfileTheme.avatarRingGradient,
        boxShadow: [
          BoxShadow(
            color: FriendProfileTheme.glowPurple.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: FriendProfileTheme.backgroundBottom,
        ),
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: MomentAvatar(
            name: profile.displayName,
            imageUrl: profile.avatarUrl,
            size: FriendProfileTheme.avatarInner,
          ),
        ),
      ),
    );
  }
}

class _OnlineStatusPill extends StatelessWidget {
  const _OnlineStatusPill({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final isOnline = PresenceUtils.isOnline(profile.lastSeenAt);
    final label = PresenceUtils.statusLabel(
      isTyping: false,
      lastSeenAt: profile.lastSeenAt,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC121018),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline
                  ? MomentSpaceTheme.onlineGreen
                  : Colors.white.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: FriendProfileTextStyles.onlineStatus),
        ],
      ),
    );
  }
}
