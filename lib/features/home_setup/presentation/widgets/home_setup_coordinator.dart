import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/lifecycle/app_lifecycle_cubit.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/features/friends/presentation/cubit/friends_cubit.dart';
import 'package:moment/features/home_setup/domain/entities/setup_requirement.dart';
import 'package:moment/features/home_setup/presentation/cubit/home_setup_cubit.dart';
import 'package:moment/features/home_setup/presentation/cubit/home_setup_state.dart';
import 'package:moment/features/home_setup/presentation/widgets/friend_connected_celebration_sheet.dart';
import 'package:moment/features/home_setup/presentation/widgets/mandatory_friend_setup_sheet.dart';
import 'package:moment/features/home_setup/presentation/widgets/widget_reminder_sheet.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

/// Presents mandatory friend setup and optional widget reminders over Home.
class HomeSetupCoordinator extends StatefulWidget {
  const HomeSetupCoordinator({required this.child, super.key});

  final Widget child;

  @override
  State<HomeSetupCoordinator> createState() => _HomeSetupCoordinatorState();
}

class _HomeSetupCoordinatorState extends State<HomeSetupCoordinator> {
  late final HomeSetupCubit _setupCubit;
  StreamSubscription<AppLifecycleStateView>? _lifecycleSub;
  var _presentingSheet = false;

  @override
  void initState() {
    super.initState();
    _setupCubit = sl<HomeSetupCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_setupCubit.onHomeOpened());
    });
    _lifecycleSub = sl<AppLifecycleCubit>().stream.listen((view) {
      if (view.status == AppLifecycleState.resumed) {
        unawaited(_setupCubit.onHomeOpened());
      }
    });
  }

  @override
  void dispose() {
    unawaited(_lifecycleSub?.cancel());
    unawaited(_setupCubit.close());
    super.dispose();
  }

  Future<void> _maybePresentSheet(BuildContext context, HomeSetupState setup) async {
    if (_presentingSheet || setup.sheetVisible) return;
    if (setup.status != HomeSetupStatus.ready) return;

    switch (setup.requirement) {
      case SetupRequirement.friendsRequired:
        await _showMandatoryFriendSheet(context);
      case SetupRequirement.friendConnectedCelebration:
        await _showFriendConnectedCelebrationSheet(context);
      case SetupRequirement.widgetReminder:
        await _showWidgetReminderSheet(context);
      case SetupRequirement.none:
      case SetupRequirement.checkFailed:
        break;
    }
  }

  Future<void> _dismissOpenSetupSheet(BuildContext context) async {
    if (!_presentingSheet) return;
    Navigator.of(context).pop();
    _presentingSheet = false;
    _setupCubit.onSheetClosed();
  }

  Future<void> _showFriendConnectedCelebrationSheet(BuildContext context) async {
    await _dismissOpenSetupSheet(context);
    if (!mounted) return;

    _presentingSheet = true;
    _setupCubit.onSheetPresented();

    final friendsState = context.read<FriendsCubit>().state;
    UserProfile? friend;
    if (friendsState.friends.isNotEmpty) {
      friend = friendsState.friends.first.profile;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surfaceDark,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return PopScope(
          canPop: false,
          child: FriendConnectedCelebrationSheet(
            friend: friend,
            onContinue: () => Navigator.of(sheetContext).pop(),
          ),
        );
      },
    );

    _presentingSheet = false;
    _setupCubit.onSheetClosed();
    if (!mounted) return;
    unawaited(_setupCubit.onFriendConnectedCelebrationCompleted());
  }

  Future<void> _showMandatoryFriendSheet(BuildContext context) async {
    _presentingSheet = true;
    _setupCubit.onSheetPresented();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surfaceDark,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return PopScope(
          canPop: false,
          child: MandatoryFriendSetupSheet(
            onSearchUsername: () {
              Navigator.of(sheetContext).pop();
              context.push(AppRoutes.friends);
            },
            onScanQr: () {
              Navigator.of(sheetContext).pop();
              context.push(AppRoutes.friendsScan);
            },
          ),
        );
      },
    );

    _presentingSheet = false;
    _setupCubit.onSheetClosed();
    if (!mounted) return;
    final latest = _setupCubit.state;
    if (latest.requirement == SetupRequirement.friendsRequired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_setupCubit.onHomeOpened());
      });
    }
  }

  Future<void> _showWidgetReminderSheet(BuildContext context) async {
    _presentingSheet = true;
    _setupCubit.onSheetPresented();
    unawaited(_setupCubit.onWidgetReminderShown());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return WidgetReminderSheet(
          onMaybeLater: () {
            Navigator.of(sheetContext).pop();
            unawaited(_setupCubit.onWidgetMaybeLater());
          },
          onWidgetConfirmed: () {
            Navigator.of(sheetContext).pop();
            unawaited(_setupCubit.onWidgetSetupConfirmed());
          },
        );
      },
    );

    _presentingSheet = false;
    _setupCubit.onSheetClosed();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider.value(value: _setupCubit)],
      child: BlocListener<FriendsCubit, FriendsState>(
        listenWhen: (prev, next) =>
            prev.friends.length != next.friends.length ||
            prev.status != next.status,
        listener: (context, friendsState) {
          unawaited(_setupCubit.refreshAfterFriendshipChange());
        },
        child: BlocListener<HomeSetupCubit, HomeSetupState>(
          listenWhen: (prev, next) =>
              prev.requirement != next.requirement ||
              prev.status != next.status,
          listener: (context, setupState) {
            if (setupState.status == HomeSetupStatus.failed &&
                setupState.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(setupState.errorMessage!),
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: () => _setupCubit.retry(),
                  ),
                ),
              );
            }
            unawaited(_maybePresentSheet(context, setupState));
          },
          child: widget.child,
        ),
      ),
    );
  }
}
