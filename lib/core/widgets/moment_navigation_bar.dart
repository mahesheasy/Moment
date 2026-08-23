import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_component_sizes.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_shadows.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/theme/moment_theme.dart';

enum MomentNavItem { home, circles, memories, profile }

class MomentNavigationBar extends StatelessWidget {
  const MomentNavigationBar({
    required this.current,
    required this.onTap,
    required this.onCameraTap,
    super.key,
  });

  final MomentNavItem current;
  final ValueChanged<MomentNavItem> onTap;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: mc.background,
        border: Border(
          top: BorderSide(color: mc.border, width: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottom),
        child: SizedBox(
          height: AppComponentSizes.navBarHeight,
          child: Row(
            children: [
              _NavItem(
                icon: AppIcons.home,
                selectedIcon: AppIcons.homeFilled,
                label: 'Home',
                selected: current == MomentNavItem.home,
                onTap: () => onTap(MomentNavItem.home),
              ),
              _NavItem(
                icon: AppIcons.circles,
                selectedIcon: AppIcons.circlesFilled,
                label: 'Circles',
                selected: current == MomentNavItem.circles,
                onTap: () => onTap(MomentNavItem.circles),
              ),
              _CameraButton(onTap: onCameraTap),
              _NavItem(
                icon: AppIcons.memories,
                selectedIcon: AppIcons.memoriesFilled,
                label: 'Memories',
                selected: current == MomentNavItem.memories,
                onTap: () => onTap(MomentNavItem.memories),
              ),
              _NavItem(
                icon: AppIcons.profile,
                selectedIcon: AppIcons.profileFilled,
                label: 'Profile',
                selected: current == MomentNavItem.profile,
                onTap: () => onTap(MomentNavItem.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final color = selected ? mc.accent : mc.textTertiary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, size: AppComponentSizes.iconLg, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                  height: 1,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return Semantics(
      button: true,
      label: 'Take a moment',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: mc.bloomGradient,
            boxShadow: AppShadows.cameraGlow,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: AppComponentSizes.navCamera,
                height: AppComponentSizes.navCamera,
                child: Icon(
                  AppIcons.cameraFilled,
                  color: Colors.white,
                  size: AppComponentSizes.iconLg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension MomentNavRouting on MomentNavItem {
  String get route => switch (this) {
    MomentNavItem.home => AppRoutes.home,
    MomentNavItem.circles => AppRoutes.circles,
    MomentNavItem.memories => AppRoutes.memories,
    MomentNavItem.profile => AppRoutes.profile,
  };

  static MomentNavItem fromLocation(String location) {
    if (location.startsWith(AppRoutes.circles)) {
      return MomentNavItem.circles;
    }
    if (location.startsWith(AppRoutes.memories)) {
      return MomentNavItem.memories;
    }
    if (location.startsWith(AppRoutes.profile)) {
      return MomentNavItem.profile;
    }
    return MomentNavItem.home;
  }
}

void navigateShellTab(BuildContext context, MomentNavItem item) {
  context.go(item.route);
}
