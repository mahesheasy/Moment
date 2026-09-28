import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/features/home_setup/presentation/constants/home_setup_assets.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class FriendConnectedCelebrationSheet extends StatelessWidget {
  const FriendConnectedCelebrationSheet({
    required this.onContinue,
    this.friend,
    super.key,
  });

  final VoidCallback onContinue;
  final UserProfile? friend;

  @override
  Widget build(BuildContext context) {
    final displayName = friend?.displayName ?? 'Your friend';
    final username = friend?.username;

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
            SizedBox(
              height: 160,
              child: Lottie.asset(
                HomeSetupAssets.friendConnectedLottie,
                fit: BoxFit.contain,
                repeat: false,
                errorBuilder: (_, __, ___) {
                  return Image.asset(
                    'assets/images/onboarding/connected.png',
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "You're Connected! ❤️",
              style: SettingsType.title(AppColors.textPrimaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (friend != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MomentAvatar(
                    imageUrl: friend!.avatarUrl,
                    name: displayName,
                    size: 56,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: SettingsType.title(AppColors.textPrimaryDark),
                      ),
                      if (username != null && username.isNotEmpty)
                        Text(
                          '@$username',
                          style: SettingsType.body(AppColors.textSecondaryDark),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            MomentButton(
              label: 'Continue',
              size: MomentButtonSize.large,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
