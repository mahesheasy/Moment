import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/navigation/memories_overlay_controller.dart';
import 'package:moment/core/widgets/moment_navigation_bar.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/features/chat/presentation/cubit/chat_inbox_cubit.dart';
import 'package:moment/features/memories/presentation/cubit/memory_cubit.dart';
import 'package:moment/features/memories/presentation/widgets/snap_memories_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final MemoriesOverlayController _memoriesOverlay;

  @override
  void initState() {
    super.initState();
    _memoriesOverlay = sl<MemoriesOverlayController>();
    _memoriesOverlay.addListener(_onOverlayChanged);
    sl<ChatInboxCubit>().load();
  }

  @override
  void dispose() {
    _memoriesOverlay.removeListener(_onOverlayChanged);
    super.dispose();
  }

  void _onOverlayChanged() => setState(() {});

  void _onNavTap(MomentNavItem item) {
    if (_memoriesOverlay.isOpen) {
      _memoriesOverlay.close();
    }

    final index = switch (item) {
      MomentNavItem.home => 0,
      MomentNavItem.circles => 1,
      MomentNavItem.chat => 2,
      MomentNavItem.profile => 3,
    };
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  bool get _hideBottomNav => _memoriesOverlay.isOpen;

  @override
  Widget build(BuildContext context) {
    final current = MomentNavItem.values[widget.navigationShell.currentIndex];

    return BlocProvider.value(
      value: sl<ChatInboxCubit>(),
      child: MomentScaffold(
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            widget.navigationShell,
            AnimatedSlide(
              offset: _memoriesOverlay.isOpen ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: _memoriesOverlay.isOpen
                  ? BlocProvider(
                      create: (_) => sl<MemoryVaultCubit>()..load(),
                      child: SnapMemoriesView(
                        mode: SnapMemoriesMode.overlay,
                        onDismiss: _memoriesOverlay.close,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      bottomNavigationBar: _hideBottomNav
          ? null
          : MomentNavigationBar(
              current: current,
              onTap: _onNavTap,
              onCameraTap: () => context.push(AppRoutes.camera),
            ),
      ),
    );
  }
}
