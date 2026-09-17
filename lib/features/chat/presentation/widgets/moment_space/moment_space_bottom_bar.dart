import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_shadows.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';

enum MomentSpaceNavItem { home, moments, connections, me }

class MomentSpaceBottomBar extends StatelessWidget {
  const MomentSpaceBottomBar({
    this.active = MomentSpaceNavItem.moments,
    super.key,
  });

  final MomentSpaceNavItem active;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(6, 4, 6, 4 + bottom),
      decoration: BoxDecoration(
        color: MomentSpaceTheme.background(context),
        border: Border(
          top: BorderSide(color: MomentSpaceTheme.border(context)),
        ),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: AppIcons.home,
            label: 'Home',
            selected: active == MomentSpaceNavItem.home,
            onTap: () => context.go(AppRoutes.home),
          ),
          _NavItem(
            icon: Icons.auto_awesome_outlined,
            selectedIcon: Icons.auto_awesome_rounded,
            label: 'Moments',
            selected: active == MomentSpaceNavItem.moments,
            onTap: () => context.go(AppRoutes.chat),
          ),
          _CenterAction(
            onTap: () => context.push(AppRoutes.camera),
          ),
          _NavItem(
            icon: AppIcons.circles,
            label: 'Connections',
            selected: active == MomentSpaceNavItem.connections,
            onTap: () => context.go(AppRoutes.friends),
          ),
          _NavItem(
            icon: AppIcons.profile,
            label: 'Me',
            selected: active == MomentSpaceNavItem.me,
            onTap: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.mc.accent
        : MomentSpaceTheme.textTertiary(context);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? (selectedIcon ?? icon) : icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  const _CenterAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: context.mc.bloomGradient,
              boxShadow: AppShadows.cameraGlow,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
