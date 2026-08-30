import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/features/notifications/domain/entities/app_notification.dart';
import 'package:moment/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:moment/features/notifications/presentation/widgets/notification_swipe_tile.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().start();
  }

  void _onNotificationTap(AppNotification item) {
    final cubit = context.read<NotificationsCubit>();
    cubit.markRead(item.id);

    switch (item.target) {
      case FriendNotificationTarget(:final userId):
        context.push(AppRoutes.friend(userId));
      case MomentNotificationTarget(:final momentId):
        context.push(AppRoutes.moment(momentId));
      case ChatNotificationTarget(:final userId):
        context.push(AppRoutes.chatThread(userId));
    }
  }

  void _dismissNotification(AppNotification item) {
    context.read<NotificationsCubit>().dismiss(item.id);
  }

  Future<void> _showNotificationOptions(AppNotification item) async {
    final cubit = context.read<NotificationsCubit>();

    final action = await showModalBottomSheet<_NotificationSheetAction>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.isUnread)
                _NotificationSheetTile(
                  label: 'Mark as read',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _NotificationSheetAction.markRead,
                  ),
                ),
              _NotificationSheetTile(
                label: 'Not interested',
                onTap: () => Navigator.pop(
                  sheetContext,
                  _NotificationSheetAction.notInterested,
                ),
              ),
              _NotificationSheetTile(
                label: 'Turn off notifications like this',
                onTap: () => Navigator.pop(
                  sheetContext,
                  _NotificationSheetAction.turnOffType,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _NotificationSheetAction.markRead:
        await cubit.markRead(item.id);
      case _NotificationSheetAction.notInterested:
        await cubit.dismiss(item.id);
      case _NotificationSheetAction.turnOffType:
        if (mounted) await context.push(AppRoutes.notificationSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final filtered = state.filteredItems;
        final unread = filtered.where((n) => n.isUnread).toList();
        final earlier = filtered.where((n) => !n.isUnread).toList();

        return MomentScaffold(
          appBar: MomentAppBar(
            leading: IconButton(
              icon: Icon(AppIcons.back, size: 18),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (state.unreadCount > 0)
                TextButton(
                  onPressed: () =>
                      context.read<NotificationsCubit>().markAllRead(),
                  child: Text(
                    'Mark all read',
                    style: SettingsType.caption(AppColors.violet)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              IconButton(
                icon: Icon(Icons.settings_outlined, size: 20),
                onPressed: () => context.push(AppRoutes.notificationSettings),
              ),
            ],
          ),
          body: switch (state.status) {
            NotificationsStatus.initial ||
            NotificationsStatus.loading when state.items.isEmpty =>
              const Center(child: CircularProgressIndicator()),
            NotificationsStatus.error when state.items.isEmpty =>
              _ErrorState(message: state.errorMessage),
            _ => RefreshIndicator(
                onRefresh: () =>
                    context.read<NotificationsCubit>().refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.huge,
                  ),
                  children: [
                    Text(
                      'Notifications',
                      style: SettingsType.title(AppColors.textPrimaryDark)
                          .copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stay updated with what matters.',
                      style: SettingsType.body(AppColors.textTertiaryDark),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FilterRow(
                      filter: state.filter,
                      onChanged: context.read<NotificationsCubit>().setFilter,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (filtered.isEmpty)
                      const _CaughtUpCard()
                    else ...[
                      if (unread.isNotEmpty) ...[
                        const _SectionLabel(label: 'New'),
                        const SizedBox(height: AppSpacing.sm),
                        _NotificationGroup(
                          items: unread,
                          onTap: _onNotificationTap,
                          onMore: _showNotificationOptions,
                          onDelete: _dismissNotification,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      if (earlier.isNotEmpty) ...[
                        const _SectionLabel(label: 'Earlier'),
                        const SizedBox(height: AppSpacing.sm),
                        _NotificationGroup(
                          items: earlier,
                          onTap: _onNotificationTap,
                          onMore: _showNotificationOptions,
                          onDelete: _dismissNotification,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      const _CaughtUpCard(),
                    ],
                  ],
                ),
              ),
          },
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message ?? 'Could not load notifications.',
              textAlign: TextAlign.center,
              style: SettingsType.body(AppColors.textSecondaryDark),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => context.read<NotificationsCubit>().refresh(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.onChanged});

  final AppNotificationFilter filter;
  final ValueChanged<AppNotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            icon: Icons.notifications_none_rounded,
            selected: filter == AppNotificationFilter.all,
            onTap: () => onChanged(AppNotificationFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Mentions',
            icon: Icons.alternate_email_rounded,
            selected: filter == AppNotificationFilter.mentions,
            onTap: () => onChanged(AppNotificationFilter.mentions),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Updates',
            icon: Icons.campaign_outlined,
            selected: filter == AppNotificationFilter.updates,
            onTap: () => onChanged(AppNotificationFilter.updates),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'System',
            icon: Icons.settings_outlined,
            selected: filter == AppNotificationFilter.system,
            onTap: () => onChanged(AppNotificationFilter.system),
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
            const SizedBox(width: 6),
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
  const _NotificationGroup({
    required this.items,
    required this.onTap,
    required this.onMore,
    required this.onDelete,
  });

  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;
  final ValueChanged<AppNotification> onMore;
  final ValueChanged<AppNotification> onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: AppColors.surfaceDark,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++)
              NotificationSwipeTile(
                onTap: () => onTap(items[i]),
                onMore: () => onMore(items[i]),
                onDelete: () => onDelete(items[i]),
                child: _NotificationTileContent(item: items[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTileContent extends StatelessWidget {
  const _NotificationTileContent({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationLeading(item: item),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(
                  relativeTimeAgo(item.createdAt),
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

  final AppNotification item;

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
      AppNotificationType.reaction => Icons.favorite_rounded,
      AppNotificationType.moment => Icons.photo_camera_rounded,
      AppNotificationType.ping => Icons.chat_bubble_rounded,
      AppNotificationType.chat => Icons.chat_rounded,
      AppNotificationType.friendJoined => Icons.people_rounded,
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're all caught up! 🎉",
                  style: SettingsType.title(AppColors.textPrimaryDark)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
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

Widget createNotificationsPage() {
  return BlocProvider(
    create: (_) => sl<NotificationsCubit>(),
    child: const NotificationsPage(),
  );
}

enum _NotificationSheetAction { markRead, notInterested, turnOffType }

class _NotificationSheetTile extends StatelessWidget {
  const _NotificationSheetTile({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        label,
        style: SettingsType.body(AppColors.textPrimaryDark).copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
