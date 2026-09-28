import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class MandatoryFriendSetupSheet extends StatelessWidget {
  const MandatoryFriendSetupSheet({
    required this.onSearchUsername,
    required this.onScanQr,
    super.key,
  });

  final VoidCallback onSearchUsername;
  final VoidCallback onScanQr;

  @override
  Widget build(BuildContext context) {
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
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/onboarding/your_people.png',
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Start Your Moment',
              style: SettingsType.title(AppColors.textPrimaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Moment becomes meaningful when you have people to share '
              'everyday moments with.',
              style: SettingsType.body(AppColors.textSecondaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            MomentButton(
              label: 'Search Username',
              size: MomentButtonSize.large,
              onPressed: onSearchUsername,
            ),
            const SizedBox(height: AppSpacing.md),
            MomentButton(
              label: 'Scan Moment QR',
              variant: MomentButtonVariant.secondary,
              size: MomentButtonSize.large,
              onPressed: onScanQr,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Add at least 1 friend to continue',
              style: SettingsType.caption(AppColors.textSecondaryDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
