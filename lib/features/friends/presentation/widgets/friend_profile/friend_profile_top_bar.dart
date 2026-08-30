import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/friends/presentation/theme/friend_profile_theme.dart';

class FriendProfileTopBar extends StatelessWidget {
  const FriendProfileTopBar({
    required this.onBack,
    this.onMenu,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          _IconTap(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const Spacer(),
          if (onMenu != null)
            _IconTap(
              icon: Icons.more_vert_rounded,
              onTap: onMenu!,
            ),
        ],
      ),
    );
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: AppColors.textPrimaryDark),
        ),
      ),
    );
  }
}

class FriendProfileAmbientGlow extends StatelessWidget {
  const FriendProfileAmbientGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.35),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FriendProfileLoadingBody extends StatelessWidget {
  const FriendProfileLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        const SizedBox(height: 48),
        Center(
          child: Container(
            width: FriendProfileTheme.avatarOuter,
            height: FriendProfileTheme.avatarOuter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FriendProfileTheme.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Container(
            width: 140,
            height: 18,
            decoration: BoxDecoration(
              color: FriendProfileTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: List.generate(
            4,
            (_) => Expanded(
              child: Container(
                height: 72,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: FriendProfileTheme.surface,
                  borderRadius: BorderRadius.circular(FriendProfileTheme.cardRadius),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
