import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/friends/domain/entities/contact_suggestion.dart';
import 'package:moment/features/friends/presentation/friends_invite.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

const kFriendsGoalCount = 20;
const kFriendAddYellow = Color(0xFFF5C518);

class FriendAddPillButton extends StatelessWidget {
  const FriendAddPillButton({
    required this.label,
    super.key,
    this.onTap,
    this.isLoading = false,
    this.emphasized = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final active = onTap != null && !isLoading;
    final background = emphasized
        ? kFriendAddYellow
        : AppColors.surfaceElevatedDark;
    final foreground = emphasized
        ? const Color(0xFF111111)
        : AppColors.textSecondaryDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? background : AppColors.surfaceElevatedDark,
            borderRadius: BorderRadius.circular(999),
          ),
          child: isLoading
              ? SizedBox(
                  width: 52,
                  height: 16,
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    ),
                  ),
                )
              : Text(
                  label,
                  style: SettingsType.caption(
                    active ? foreground : AppColors.textTertiaryDark,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                ),
        ),
      ),
    );
  }
}

class FriendsQrConnectRow extends StatelessWidget {
  const FriendsQrConnectRow({
    required this.onScanTap,
    required this.onMyQrTap,
    super.key,
  });

  final VoidCallback onScanTap;
  final VoidCallback onMyQrTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QrConnectButton(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR',
            emphasized: true,
            onTap: onScanTap,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QrConnectButton(
            icon: Icons.qr_code_2_rounded,
            label: 'My QR',
            onTap: onMyQrTap,
          ),
        ),
      ],
    );
  }
}

class _QrConnectButton extends StatelessWidget {
  const _QrConnectButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final background = emphasized
        ? AppColors.violet.withValues(alpha: 0.18)
        : AppColors.surfaceElevatedDark;
    final border = emphasized
        ? AppColors.violet.withValues(alpha: 0.45)
        : AppColors.borderDark;
    final foreground = emphasized
        ? AppColors.textPrimaryDark
        : AppColors.textSecondaryDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: SettingsType.caption(foreground).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FriendsFromOtherAppsRow extends StatelessWidget {
  const FriendsFromOtherAppsRow({
    super.key,
    this.username,
    this.userId,
    this.compact = false,
  });

  final String? username;
  final String? userId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact)
          Text(
            'Find friends from other apps',
            style: SettingsType.title(
              AppColors.textPrimaryDark,
            ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _InviteAppButton(
              label: 'Insta',
              onTap: () => FriendInvite.send(
                channel: FriendInviteChannel.instagram,
                username: username,
                userId: userId,
              ),
              child: const _InstagramGlyph(),
            ),
            _InviteAppButton(
              label: 'Snap',
              onTap: () => FriendInvite.send(
                channel: FriendInviteChannel.snapchat,
                username: username,
                userId: userId,
              ),
              child: const _SnapGlyph(),
            ),
            _InviteAppButton(
              label: 'Messages',
              onTap: () => FriendInvite.send(
                channel: FriendInviteChannel.messages,
                username: username,
                userId: userId,
              ),
              child: const _MessagesGlyph(),
            ),
            _InviteAppButton(
              label: 'Others',
              onTap: () => FriendInvite.send(
                channel: FriendInviteChannel.others,
                username: username,
                userId: userId,
              ),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Icon(
                  Icons.ios_share_rounded,
                  color: AppColors.textPrimaryDark,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FriendsUsernameTipCard extends StatelessWidget {
  const FriendsUsernameTipCard({
    required this.username,
    required this.onDismiss,
    super.key,
  });

  final String username;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            Icon(
              AppIcons.circlesFilled,
              color: AppColors.textPrimaryDark,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tip! Add by username',
                    style: SettingsType.title(
                      AppColors.textPrimaryDark,
                    ).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Scan QR or search @$username',
                    style: SettingsType.body(AppColors.textTertiaryDark),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                AppIcons.close,
                size: 18,
                color: AppColors.textTertiaryDark,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteAppButton extends StatelessWidget {
  const _InviteAppButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            child,
            const SizedBox(height: 8),
            Text(
              label,
              style: SettingsType.caption(
                AppColors.textPrimaryDark,
              ).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstagramGlyph extends StatelessWidget {
  const _InstagramGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
            Color(0xFF515BD4),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnapGlyph extends StatelessWidget {
  const _SnapGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFC00),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.chat_bubble_rounded,
          color: Color(0xFF111111),
          size: 28,
        ),
      ),
    );
  }
}

class _MessagesGlyph extends StatelessWidget {
  const _MessagesGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF34C759),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class FriendsContactsSection extends StatefulWidget {
  const FriendsContactsSection({
    required this.contacts,
    required this.contactsLoaded,
    required this.permissionDenied,
    required this.onRequestAccess,
    this.username,
    this.previewCount = 4,
    super.key,
  });

  final List<ContactSuggestion> contacts;
  final bool contactsLoaded;
  final bool permissionDenied;
  final VoidCallback onRequestAccess;
  final String? username;
  final int previewCount;

  @override
  State<FriendsContactsSection> createState() => _FriendsContactsSectionState();
}

class _FriendsContactsSectionState extends State<FriendsContactsSection> {
  var _showAllContacts = false;

  @override
  Widget build(BuildContext context) {
    final contacts = widget.contacts;
    final contactsLoaded = widget.contactsLoaded;
    final permissionDenied = widget.permissionDenied;
    final username = widget.username;
    final previewCount = widget.previewCount;
    if (!contactsLoaded) {
      return const SizedBox.shrink();
    }

    if (permissionDenied) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'From your contacts',
            style: SettingsType.title(AppColors.textPrimaryDark).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: ListTile(
              onTap: widget.onRequestAccess,
              leading: const Icon(Icons.contacts_rounded, color: Colors.white),
              title: Text(
                'Allow contacts access',
                style: SettingsType.title(AppColors.textPrimaryDark),
              ),
              subtitle: Text(
                'Find people you know and invite them to Moment.',
                style: SettingsType.body(AppColors.textTertiaryDark),
              ),
              trailing: Icon(
                AppIcons.chevronRight,
                color: AppColors.textTertiaryDark,
                size: 18,
              ),
            ),
          ),
        ],
      );
    }

    if (contacts.isEmpty) return const SizedBox.shrink();

    final visibleContacts = _showAllContacts
        ? contacts
        : contacts.take(previewCount).toList();
    final hiddenCount = contacts.length - previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'From your contacts',
          style: SettingsType.title(AppColors.textPrimaryDark).copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                for (var i = 0; i < visibleContacts.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppColors.borderDark),
                  _ContactInviteRow(
                    contact: visibleContacts[i],
                    username: username,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!_showAllContacts && hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => setState(() => _showAllContacts = true),
                child: Text(
                  'Show all $hiddenCount contacts',
                  style: SettingsType.caption(AppColors.violet).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ContactInviteRow extends StatelessWidget {
  const _ContactInviteRow({
    required this.contact,
    required this.username,
  });

  final ContactSuggestion contact;
  final String? username;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceElevatedDark,
            child: Text(
              contact.displayName.characters.first.toUpperCase(),
              style: SettingsType.title(AppColors.textPrimaryDark)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName,
                  style: SettingsType.title(AppColors.textPrimaryDark)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (contact.phone != null)
                  Text(
                    contact.phone!,
                    style: SettingsType.caption(AppColors.textTertiaryDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          FriendAddPillButton(
            label: 'Invite',
            onTap: () => FriendInvite.send(
              channel: contact.phone != null
                  ? FriendInviteChannel.messages
                  : FriendInviteChannel.others,
              username: username,
            ),
          ),
        ],
      ),
    );
  }
}
