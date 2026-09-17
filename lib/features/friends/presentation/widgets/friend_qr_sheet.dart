import 'package:flutter/material.dart';
import 'package:moment/core/deep_links/moment_qr_link.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/features/friends/presentation/friend_qr_share.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<void> showFriendQrSheet(
  BuildContext context, {
  required UserProfile profile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceDark,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.sm,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: _FriendQrSheetBody(profile: profile),
        ),
      );
    },
  );
}

class _FriendQrSheetBody extends StatefulWidget {
  const _FriendQrSheetBody({required this.profile});

  final UserProfile profile;

  @override
  State<_FriendQrSheetBody> createState() => _FriendQrSheetBodyState();
}

class _FriendQrSheetBodyState extends State<_FriendQrSheetBody> {
  var _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await FriendQrShare.share(
        userId: widget.profile.id,
        username: widget.profile.username,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share QR code. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final qrData = MomentQrLink.qrPayload(profile.id);
    final shareLink = MomentQrLink.friendProfile(profile.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'My Moment QR',
          style: SettingsType.title(
            AppColors.textPrimaryDark,
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Let friends scan to connect instantly.',
          textAlign: TextAlign.center,
          style: SettingsType.body(AppColors.textTertiaryDark),
        ),
        const SizedBox(height: AppSpacing.xl),
        MomentAvatar(
          imageUrl: profile.avatarUrl,
          name: profile.displayName,
          size: 56,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          profile.displayName,
          style: SettingsType.title(
            AppColors.textPrimaryDark,
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          '@${profile.username}',
          style: SettingsType.body(AppColors.textTertiaryDark),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.violet.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 220,
            padding: const EdgeInsets.all(4),
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ask a friend to scan this with Moment.',
          textAlign: TextAlign.center,
          style: SettingsType.caption(AppColors.textTertiaryDark),
        ),
        const SizedBox(height: AppSpacing.lg),
        MomentButton(
          label: 'Share QR code',
          isLoading: _sharing,
          onPressed: _sharing ? null : _share,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          shareLink,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: SettingsType.caption(AppColors.textTertiaryDark).copyWith(
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
