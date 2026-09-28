import 'dart:io';

import 'package:flutter/material.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widget/android_widget_bridge.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/widget_style_preview.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';

class WidgetReminderSheet extends StatelessWidget {
  const WidgetReminderSheet({
    required this.onMaybeLater,
    required this.onWidgetConfirmed,
    super.key,
  });

  final VoidCallback onMaybeLater;
  final VoidCallback onWidgetConfirmed;

  Future<void> _addWidget(BuildContext context) async {
    if (Platform.isAndroid) {
      final pinned = await sl<AndroidWidgetBridge>().requestPinToHomeScreen();
      if (pinned) {
        onWidgetConfirmed();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Confirm adding Moment on your home screen, or tap '
                '"I\'ve Added the Widget" when done.',
              ),
            ),
          );
        }
        return;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Long-press your home screen, open Widgets, then add Moment.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewPrefs = WidgetPreferences.defaults();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.sm,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: WidgetStylePreview(
                preferences: previewPrefs,
                headerTitle: 'Friend',
                compact: true,
                previewSize: 140,
                borderless: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Keep Moment Close',
              style: SettingsType.title(AppColors.textPrimaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add the Moment widget to your home screen and see moments '
              'from your friends instantly.',
              style: SettingsType.body(AppColors.textSecondaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            MomentButton(
              label: 'Add Widget',
              size: MomentButtonSize.large,
              onPressed: () => _addWidget(context),
            ),
            const SizedBox(height: AppSpacing.md),
            MomentButton(
              label: "I've Added the Widget",
              variant: MomentButtonVariant.secondary,
              size: MomentButtonSize.large,
              onPressed: onWidgetConfirmed,
            ),
            const SizedBox(height: AppSpacing.md),
            MomentButton(
              label: 'Maybe Later',
              variant: MomentButtonVariant.ghost,
              size: MomentButtonSize.large,
              onPressed: onMaybeLater,
            ),
          ],
        ),
      ),
    );
  }
}
