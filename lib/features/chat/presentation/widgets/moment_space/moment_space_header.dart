import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_hero_tags.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/chat/presentation/theme/chat_typography.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

typedef MomentSpaceMenuCallback = void Function();

class MomentSpaceHeader extends StatelessWidget {
  const MomentSpaceHeader({
    required this.user,
    required this.showHero,
    this.onMenu,
    super.key,
  });

  final UserProfile user;
  final bool showHero;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final status = user.bio?.trim().isNotEmpty == true
        ? user.bio!
        : 'Good vibes only 🌿';

    return Container(
      padding: EdgeInsets.fromLTRB(8, top + 4, 12, 12),
      decoration: BoxDecoration(
        color: MomentSpaceTheme.background.withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              AppIcons.back,
              size: 22,
              color: MomentSpaceTheme.textPrimary(context),
            ),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: InkWell(
              onTap: () => context.push(AppRoutes.friend(user.id)),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  _AvatarWithOnline(
                    user: user,
                    showHero: showHero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ChatTypography.headerName(
                                  color: MomentSpaceTheme.textPrimary(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 12,
                              color: context.mc.accent,
                            ),
                          ],
                        ),
                        Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ChatTypography.headerStatus(
                            color: MomentSpaceTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onMenu != null)
            _HeaderIconButton(
              icon: Icons.more_vert_rounded,
              onTap: onMenu,
            ),
        ],
      ),
    );
  }
}

class _AvatarWithOnline extends StatelessWidget {
  const _AvatarWithOnline({required this.user, required this.showHero});

  final UserProfile user;
  final bool showHero;

  @override
  Widget build(BuildContext context) {
    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        MomentAvatar(
          name: user.displayName,
          imageUrl: user.avatarUrl,
          size: MomentSpaceTheme.avatarHeader,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: MomentSpaceTheme.onlineGreen,
              shape: BoxShape.circle,
              border: Border.all(
                color: MomentSpaceTheme.background,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );

    if (!showHero) return avatar;

    return Hero(
      tag: MomentHeroTags.chatAvatar(user.id),
      child: Material(color: Colors.transparent, child: avatar),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: MomentSpaceTheme.iconButtonSize,
            height: MomentSpaceTheme.iconButtonSize,
            decoration: MomentSpaceTheme.iconButtonDecoration(context),
            child: Icon(
              icon,
              size: 16,
              color: MomentSpaceTheme.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }
}
