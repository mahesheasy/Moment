import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_hero_tags.dart';
import 'package:moment/features/chat/presentation/theme/chat_typography.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'package:moment/features/profile/domain/presence_utils.dart';

typedef MomentSpaceMenuCallback = void Function();

class MomentSpaceHeader extends StatefulWidget {
  const MomentSpaceHeader({
    required this.user,
    required this.showHero,
    this.isTyping = false,
    this.onMenu,
    super.key,
  });

  final UserProfile user;
  final bool showHero;
  final bool isTyping;
  final VoidCallback? onMenu;

  @override
  State<MomentSpaceHeader> createState() => _MomentSpaceHeaderState();
}

class _MomentSpaceHeaderState extends State<MomentSpaceHeader> {
  Timer? _presenceTimer;

  @override
  void initState() {
    super.initState();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final top = MediaQuery.paddingOf(context).top;
    final isOnline = PresenceUtils.isOnline(widget.user.lastSeenAt);
    final status = PresenceUtils.statusLabel(
      isTyping: widget.isTyping,
      lastSeenAt: widget.user.lastSeenAt,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(8, top + 4, 12, 12),
      decoration: BoxDecoration(
        color: mc.background.withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(
            color: mc.border.withValues(alpha: 0.55),
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
              color: mc.textPrimary,
            ),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: InkWell(
              onTap: () => context.push(AppRoutes.friend(widget.user.id)),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  _AvatarWithPresence(
                    user: widget.user,
                    showHero: widget.showHero,
                    isOnline: isOnline,
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
                                widget.user.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ChatTypography.headerName(
                                  color: mc.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 12,
                              color: mc.accent,
                            ),
                          ],
                        ),
                        Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ChatTypography.headerStatus(
                            color: widget.isTyping
                                ? mc.accent
                                : isOnline
                                ? MomentSpaceTheme.onlineGreen
                                : mc.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.onMenu != null)
            _HeaderIconButton(
              icon: Icons.more_vert_rounded,
              onTap: widget.onMenu,
            ),
        ],
      ),
    );
  }
}

class _AvatarWithPresence extends StatelessWidget {
  const _AvatarWithPresence({
    required this.user,
    required this.showHero,
    required this.isOnline,
  });

  final UserProfile user;
  final bool showHero;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
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
              color: isOnline
                  ? MomentSpaceTheme.onlineGreen
                  : mc.textTertiary.withValues(alpha: 0.65),
              shape: BoxShape.circle,
              border: Border.all(
                color: mc.background,
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
              color: context.mc.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
