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
    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listenWhen: (prev, next) =>
          prev.errorMessage != next.errorMessage ||
          prev.actionMessage != next.actionMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.actionMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
        }
      },
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
                    style: SettingsType.caption(
                      AppColors.violet,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              IconButton(
                icon: Icon(Icons.settings_outlined, size: 20),
                onPressed: () => context.push(AppRoutes.notificationSettings),
              ),
            ],
          ),
          body: switch (state.status) {
            NotificationsStatus.initial || NotificationsStatus.loading
                when state.items.isEmpty =>
              const Center(child: CircularProgressIndicator()),
            NotificationsStatus.error when state.items.isEmpty => _ErrorState(
              message: state.errorMessage,
            ),
            _ => RefreshIndicator(
              onRefresh: () => context.read<NotificationsCubit>().refresh(),
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
                    style: SettingsType.title(
                      AppColors.textPrimaryDark,
                    ).copyWith(fontSize: 26, fontWeight: FontWeight.w700),
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
                        actingOn: state.actingOn,
                        onTap: _onNotificationTap,
                        onMore: _showNotificationOptions,
                        onDelete: _dismissNotification,
                        onAcceptFriendRequest: (item) => context
                            .read<NotificationsCubit>()
                            .acceptFriendRequest(item),
                        onRejectFriendRequest: (item) => context
                            .read<NotificationsCubit>()
                            .rejectFriendRequest(item),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    if (earlier.isNotEmpty) ...[
                      const _SectionLabel(label: 'Earlier'),
                      const SizedBox(height: AppSpacing.sm),
                      _NotificationGroup(
                        items: earlier,
                        actingOn: state.actingOn,
                        onTap: _onNotificationTap,
                        onMore: _showNotificationOptions,
                        onDelete: _dismissNotification,
                        onAcceptFriendRequest: (item) => context
                            .read<NotificationsCubit>()
                            .acceptFriendRequest(item),
                        onRejectFriendRequest: (item) => context
                            .read<NotificationsCubit>()
                            .rejectFriendRequest(item),
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
            label: 'Moments',
            icon: Icons.photo_camera_rounded,
            selected: filter == AppNotificationFilter.moments,
            accent: AppColors.sendCoral,
            onTap: () => onChanged(AppNotificationFilter.moments),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Chats',
            icon: Icons.chat_bubble_rounded,
            selected: filter == AppNotificationFilter.chats,
            accent: const Color(0xFF6B8AFF),
            onTap: () => onChanged(AppNotificationFilter.chats),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Social',
            icon: Icons.people_alt_rounded,
            selected: filter == AppNotificationFilter.social,
            onTap: () => onChanged(AppNotificationFilter.social),
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
    this.accent,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final chipAccent = accent ?? AppColors.violet;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? chipAccent.withValues(alpha: 0.22)
              : AppColors.surfaceDark,
          border: Border.all(
            color: selected ? chipAccent : AppColors.borderDark,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? chipAccent : AppColors.textTertiaryDark,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: SettingsType.caption(
                selected ? chipAccent : AppColors.textTertiaryDark,
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
      style: SettingsType.title(
        AppColors.textPrimaryDark,
      ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({
    required this.items,
    required this.onTap,
    required this.onMore,
    required this.onDelete,
    this.actingOn,
    this.onAcceptFriendRequest,
    this.onRejectFriendRequest,
  });

  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;
  final ValueChanged<AppNotification> onMore;
  final ValueChanged<AppNotification> onDelete;
  final String? actingOn;
  final ValueChanged<AppNotification>? onAcceptFriendRequest;
  final ValueChanged<AppNotification>? onRejectFriendRequest;

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
                child: _NotificationTileContent(
                  item: items[i],
                  actingOn: actingOn,
                  onAcceptFriendRequest: onAcceptFriendRequest,
                  onRejectFriendRequest: onRejectFriendRequest,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTileContent extends StatelessWidget {
  const _NotificationTileContent({
    required this.item,
    this.actingOn,
    this.onAcceptFriendRequest,
    this.onRejectFriendRequest,
  });

  final AppNotification item;
  final String? actingOn;
  final ValueChanged<AppNotification>? onAcceptFriendRequest;
  final ValueChanged<AppNotification>? onRejectFriendRequest;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForType(item.type);
    final typeLabel = _typeLabel(item.type);

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _NotificationLeading(item: item, accent: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: SettingsType.caption(accent).copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (item.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: SettingsType.body(AppColors.textSecondaryDark),
                      children: [
                        TextSpan(
                          text: item.title,
                          style: TextStyle(
                            color: accent,
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
            if (_showFriendRequestActions) ...[
              const SizedBox(width: 10),
              _FriendRequestNotificationActions(
                item: item,
                actingOn: actingOn,
                onAccept: onAcceptFriendRequest,
                onReject: onRejectFriendRequest,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _showFriendRequestActions {
    if (item.type != AppNotificationType.friendRequest) return false;
    final target = item.target;
    return target is FriendNotificationTarget && target.requestId != null;
  }

  Color _accentForType(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.chat => const Color(0xFF6B8AFF),
      AppNotificationType.moment ||
      AppNotificationType.reaction ||
      AppNotificationType.ping => AppColors.sendCoral,
      AppNotificationType.friendRequest ||
      AppNotificationType.friendJoined => AppColors.violet,
    };
  }

  String _typeLabel(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.chat => 'CHAT',
      AppNotificationType.moment => 'MOMENT',
      AppNotificationType.reaction => 'REACTION',
      AppNotificationType.ping => 'PING',
      AppNotificationType.friendRequest => 'REQUEST',
      AppNotificationType.friendJoined => 'ACCEPTED',
    };
  }
}

class _FriendRequestNotificationActions extends StatelessWidget {
  const _FriendRequestNotificationActions({
    required this.item,
    required this.actingOn,
    required this.onAccept,
    required this.onReject,
  });

  static const _rejectRed = Color(0xFFED4956);

  final AppNotification item;
  final String? actingOn;
  final ValueChanged<AppNotification>? onAccept;
  final ValueChanged<AppNotification>? onReject;

  @override
  Widget build(BuildContext context) {
    final target = item.target as FriendNotificationTarget;
    final requestId = target.requestId!;
    final isAccepting = actingOn == 'accept:$requestId';
    final isRejecting = actingOn == 'reject:$requestId';
    final isBusy = isAccepting || isRejecting;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FriendRequestActionIcon(
          icon: Icons.close_rounded,
          iconColor: _rejectRed,
          borderColor: _rejectRed.withValues(alpha: 0.45),
          backgroundColor: _rejectRed.withValues(alpha: 0.12),
          isLoading: isRejecting,
          onTap: isBusy ? null : () => onReject?.call(item),
        ),
        const SizedBox(width: 8),
        _FriendRequestActionIcon(
          icon: Icons.check_rounded,
          filled: true,
          isLoading: isAccepting,
          onTap: isBusy ? null : () => onAccept?.call(item),
        ),
      ],
    );
  }
}

class _FriendRequestActionIcon extends StatelessWidget {
  const _FriendRequestActionIcon({
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.isLoading = false,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool isLoading;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = filled
        ? Colors.white
        : iconColor ?? AppColors.textSecondaryDark;
    final resolvedBackground = filled
        ? AppColors.violet
        : backgroundColor ?? AppColors.surfaceElevatedDark;

    return Material(
      color: resolvedBackground,
      shape: CircleBorder(
        side: filled || borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: resolvedIconColor,
                    ),
                  )
                : Icon(icon, size: 17, color: resolvedIconColor),
          ),
        ),
      ),
    );
  }
}

class _NotificationLeading extends StatelessWidget {
  const _NotificationLeading({required this.item, required this.accent});

  final AppNotification item;
  final Color accent;

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
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceDark, width: 2),
              ),
              child: Icon(_typeIcon(item.type), size: 10, color: Colors.white),
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
      child: Icon(_typeIcon(item.type), size: 18, color: accent),
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
              'assets/images/auth_logo_m.png',
              width: 64,
              height: 64,
              fit: BoxFit.contain,
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
                  style: SettingsType.title(
                    AppColors.textPrimaryDark,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
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
  const _NotificationSheetTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        label,
        style: SettingsType.body(
          AppColors.textPrimaryDark,
        ).copyWith(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
