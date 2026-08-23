import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

enum _NotificationFilter { all, mentions, updates, system }

enum AppNotificationType { friendRequest, like, mention, friendJoined, memory, security, badge }

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.isUnread,
    this.avatarName,
    this.avatarUrl,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final String timeAgo;
  final bool isUnread;
  final String? avatarName;
  final String? avatarUrl;
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _NotificationFilter _filter = _NotificationFilter.all;

  static const _items = [
    AppNotificationItem(
      id: '1',
      type: AppNotificationType.friendRequest,
      title: 'Mahesh',
      body: 'sent you a friend request.',
      timeAgo: '2m ago',
      isUnread: true,
      avatarName: 'Mahesh',
    ),
    AppNotificationItem(
      id: '2',
      type: AppNotificationType.like,
      title: 'Sneha',
      body: 'liked your moment.',
      timeAgo: '15m ago',
      isUnread: true,
      avatarName: 'Sneha',
    ),
    AppNotificationItem(
      id: '3',
      type: AppNotificationType.mention,
      title: 'Arjun',
      body: 'mentioned you in a moment.',
      timeAgo: '1h ago',
      isUnread: true,
      avatarName: 'Arjun',
    ),
    AppNotificationItem(
      id: '4',
      type: AppNotificationType.friendJoined,
      title: 'Jay',
      body: 'joined Moment.',
      timeAgo: '3h ago',
      isUnread: false,
      avatarName: 'Jay',
    ),
    AppNotificationItem(
      id: '5',
      type: AppNotificationType.memory,
      title: 'Goa Trip',
      body: 'Your memory is ready to view.',
      timeAgo: '5h ago',
      isUnread: false,
    ),
    AppNotificationItem(
      id: '6',
      type: AppNotificationType.security,
      title: 'Security',
      body: 'Two-factor authentication is now enabled.',
      timeAgo: '1d ago',
      isUnread: false,
    ),
    AppNotificationItem(
      id: '7',
      type: AppNotificationType.badge,
      title: 'Memory Keeper',
      body: "You earned a new badge 🎉",
      timeAgo: '2d ago',
      isUnread: false,
    ),
  ];

  List<AppNotificationItem> get _filtered {
    return switch (_filter) {
      _NotificationFilter.all => _items,
      _NotificationFilter.mentions =>
        _items.where((n) => n.type == AppNotificationType.mention).toList(),
      _NotificationFilter.updates => _items
          .where(
            (n) =>
                n.type == AppNotificationType.like ||
                n.type == AppNotificationType.memory ||
                n.type == AppNotificationType.friendJoined ||
                n.type == AppNotificationType.badge,
          )
          .toList(),
      _NotificationFilter.system => _items
          .where(
            (n) =>
                n.type == AppNotificationType.security ||
                n.type == AppNotificationType.friendRequest,
          )
          .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final unread = filtered.where((n) => n.isUnread).toList();
    final earlier = filtered.where((n) => !n.isUnread).toList();

    return MomentScaffold(
      appBar: MomentAppBar(
        leading: IconButton(
          icon: Icon(AppIcons.back, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.push(AppRoutes.notificationSettings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        children: [
          Text(
            'Notifications',
            style: SettingsType.title(AppColors.textPrimaryDark).copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Stay updated with what matters.',
            style: SettingsType.body(AppColors.textTertiaryDark),
          ),
          SizedBox(height: AppSpacing.lg),
          _FilterRow(
            filter: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          SizedBox(height: AppSpacing.lg),
          if (filtered.isEmpty)
            const _CaughtUpCard()
          else ...[
            if (unread.isNotEmpty) ...[
              _SectionLabel(label: 'New'),
              SizedBox(height: AppSpacing.sm),
              _NotificationGroup(items: unread),
              SizedBox(height: AppSpacing.xl),
            ],
            if (earlier.isNotEmpty) ...[
              _SectionLabel(label: 'Earlier'),
              SizedBox(height: AppSpacing.sm),
              _NotificationGroup(items: earlier),
            ],
            SizedBox(height: AppSpacing.xl),
            const _CaughtUpCard(),
          ],
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.onChanged});

  final _NotificationFilter filter;
  final ValueChanged<_NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            icon: Icons.notifications_none_rounded,
            selected: filter == _NotificationFilter.all,
            onTap: () => onChanged(_NotificationFilter.all),
          ),
          SizedBox(width: 8),
          _FilterChip(
            label: 'Mentions',
            icon: Icons.alternate_email_rounded,
            selected: filter == _NotificationFilter.mentions,
            onTap: () => onChanged(_NotificationFilter.mentions),
          ),
          SizedBox(width: 8),
          _FilterChip(
            label: 'Updates',
            icon: Icons.campaign_outlined,
            selected: filter == _NotificationFilter.updates,
            onTap: () => onChanged(_NotificationFilter.updates),
          ),
          SizedBox(width: 8),
          _FilterChip(
            label: 'System',
            icon: Icons.settings_outlined,
            selected: filter == _NotificationFilter.system,
            onTap: () => onChanged(_NotificationFilter.system),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected ? AppColors.bloomGradient : null,
          color: selected ? null : AppColors.surfaceDark,
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.borderDark,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : AppColors.textTertiaryDark,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: SettingsType.caption(
                selected ? Colors.white : AppColors.textTertiaryDark,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: SettingsType.title(AppColors.textPrimaryDark)
          .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({required this.items});

  final List<AppNotificationItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.borderDark.withValues(alpha: 0.6),
                indent: 64,
              ),
            _NotificationTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final AppNotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationLeading(item: item),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: SettingsType.body(AppColors.textSecondaryDark),
                    children: [
                      TextSpan(
                        text: item.title,
                        style: TextStyle(
                          color: AppColors.violet,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: ' ${item.body}'),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  item.timeAgo,
                  style: SettingsType.caption(AppColors.textTertiaryDark),
                ),
              ],
            ),
          ),
          if (item.isUnread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: AppColors.violet,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationLeading extends StatelessWidget {
  const _NotificationLeading({required this.item});

  final AppNotificationItem item;

  @override
  Widget build(BuildContext context) {
    if (item.avatarName != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          MomentAvatar(
            name: item.avatarName!,
            imageUrl: item.avatarUrl,
            size: 40,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.violet,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceDark, width: 2),
              ),
              child: Icon(
                _typeIcon(item.type),
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        shape: BoxShape.circle,
      ),
      child: Icon(_typeIcon(item.type), size: 18, color: AppColors.violet),
    );
  }

  IconData _typeIcon(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.friendRequest => Icons.person_add_alt_1_rounded,
      AppNotificationType.like => Icons.favorite_rounded,
      AppNotificationType.mention => Icons.chat_bubble_rounded,
      AppNotificationType.friendJoined => Icons.people_rounded,
      AppNotificationType.memory => Icons.notifications_none_rounded,
      AppNotificationType.security => Icons.verified_user_outlined,
      AppNotificationType.badge => Icons.card_giftcard_rounded,
    };
  }
}

class _CaughtUpCard extends StatelessWidget {
  const _CaughtUpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/notifications_bell.png',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 64,
                height: 64,
                color: AppColors.surfaceElevatedDark,
                child: Icon(Icons.notifications, color: AppColors.violet),
              ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're all caught up! 🎉",
                  style: SettingsType.title(AppColors.textPrimaryDark)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  "We'll notify you when something new happens.",
                  style: SettingsType.caption(AppColors.textTertiaryDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
