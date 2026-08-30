import 'package:equatable/equatable.dart';

enum AppNotificationType {
  friendRequest,
  reaction,
  moment,
  ping,
  chat,
  friendJoined,
}

enum AppNotificationFilter { all, mentions, updates, system }

sealed class AppNotificationTarget extends Equatable {
  const AppNotificationTarget();
}

class FriendNotificationTarget extends AppNotificationTarget {
  const FriendNotificationTarget(this.userId, {this.requestId});

  final String userId;
  final String? requestId;

  @override
  List<Object?> get props => [userId, requestId];
}

class MomentNotificationTarget extends AppNotificationTarget {
  const MomentNotificationTarget(this.momentId);

  final String momentId;

  @override
  List<Object?> get props => [momentId];
}

class ChatNotificationTarget extends AppNotificationTarget {
  const ChatNotificationTarget(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isUnread,
    required this.target,
    this.avatarName,
    this.avatarUrl,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isUnread;
  final AppNotificationTarget target;
  final String? avatarName;
  final String? avatarUrl;

  bool matchesFilter(AppNotificationFilter filter) {
    return switch (filter) {
      AppNotificationFilter.all => true,
      AppNotificationFilter.mentions => type == AppNotificationType.ping,
      AppNotificationFilter.updates =>
        type == AppNotificationType.reaction ||
            type == AppNotificationType.moment ||
            type == AppNotificationType.chat ||
            type == AppNotificationType.friendJoined,
      AppNotificationFilter.system => type == AppNotificationType.friendRequest,
    };
  }

  AppNotification copyWith({bool? isUnread}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      isUnread: isUnread ?? this.isUnread,
      target: target,
      avatarName: avatarName,
      avatarUrl: avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    body,
    createdAt,
    isUnread,
    target,
    avatarName,
    avatarUrl,
  ];
}
