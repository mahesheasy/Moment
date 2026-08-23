import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/widgets/moment_navigation_bar.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onNavTap(MomentNavItem item) {
    final index = switch (item) {
      MomentNavItem.home => 0,
      MomentNavItem.circles => 1,
      MomentNavItem.memories => 2,
      MomentNavItem.profile => 3,
    };
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = MomentNavItem.values[navigationShell.currentIndex];

    return MomentScaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: MomentNavigationBar(
        current: current,
        onTap: _onNavTap,
        onCameraTap: () => context.push(AppRoutes.camera),
      ),
    );
  }
}
