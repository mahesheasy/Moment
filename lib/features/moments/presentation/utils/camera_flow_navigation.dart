import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';

/// Closes the nested camera flow (preview → send → sent) and returns to home.
void exitCameraFlowToHome(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.popUntil((route) => route.isFirst);
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    }
    router.go(AppRoutes.home);
  });
}

/// Closes the camera flow and opens the sent moment detail screen.
void exitCameraFlowToMoment(BuildContext context, String momentId) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.popUntil((route) => route.isFirst);
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    }
    router.go(AppRoutes.moment(momentId));
  });
}
