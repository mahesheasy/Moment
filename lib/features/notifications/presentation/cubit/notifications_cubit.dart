import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/notifications/domain/entities/app_notification.dart';
import 'package:moment/features/notifications/domain/repositories/notifications_repository.dart';

enum NotificationsStatus { initial, loading, ready, error }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.filter = AppNotificationFilter.all,
    this.errorMessage,
    this.actionMessage,
    this.actingOn,
  });

  final NotificationsStatus status;
  final List<AppNotification> items;
  final AppNotificationFilter filter;
  final String? errorMessage;
  final String? actionMessage;
  final String? actingOn;

  List<AppNotification> get filteredItems =>
      items.where((item) => item.matchesFilter(filter)).toList();

  int get unreadCount => items.where((item) => item.isUnread).length;

  bool isActingOn(String key) => actingOn == key;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    AppNotificationFilter? filter,
    String? errorMessage,
    String? actionMessage,
    String? actingOn,
    bool clearError = false,
    bool clearActionMessage = false,
    bool clearActing = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      actionMessage:
          clearActionMessage ? null : actionMessage ?? this.actionMessage,
      actingOn: clearActing ? null : actingOn ?? this.actingOn,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    filter,
    errorMessage,
    actionMessage,
    actingOn,
  ];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository, this._friends)
      : super(const NotificationsState());

  final NotificationsRepository _repository;
  final FriendsRepository _friends;
  StreamSubscription<List<AppNotification>>? _subscription;

  Future<void> refresh() async {
    await _subscription?.cancel();
    _subscription = null;
    emit(state.copyWith(status: NotificationsStatus.loading, clearError: true));
    start();
  }

  void start() {
    if (_subscription != null) return;
    emit(state.copyWith(status: NotificationsStatus.loading, clearError: true));

    _subscription = _repository.watchNotifications().listen(
      (items) {
        emit(
          state.copyWith(
            status: NotificationsStatus.ready,
            items: items,
            clearError: true,
          ),
        );
      },
      onError: (_) {
        emit(
          state.copyWith(
            status: NotificationsStatus.error,
            errorMessage: 'Could not load notifications.',
          ),
        );
      },
    );
  }

  void setFilter(AppNotificationFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  Future<void> markRead(String id) async {
    await _repository.markRead(id);
    emit(
      state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == id) item.copyWith(isUnread: false) else item,
        ],
      ),
    );
  }

  Future<void> markAllRead() async {
    await _repository.markAllRead();
    emit(
      state.copyWith(
        items: [
          for (final item in state.items) item.copyWith(isUnread: false),
        ],
      ),
    );
  }

  Future<void> dismiss(String id) async {
    await _repository.dismiss(id);
    emit(
      state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
      ),
    );
  }

  Future<void> acceptFriendRequest(AppNotification item) async {
    final requestId = _friendRequestId(item);
    if (requestId == null) return;

    emit(
      state.copyWith(
        actingOn: 'accept:$requestId',
        clearError: true,
        clearActionMessage: true,
      ),
    );

    final result = await _friends.acceptFriendRequest(requestId);
    switch (result) {
      case Success():
        await _repository.dismiss(item.id);
        emit(
          state.copyWith(
            clearActing: true,
            items: state.items.where((n) => n.id != item.id).toList(),
            actionMessage:
                'You and ${item.title} are now friends. Send them your first moment!',
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            clearActing: true,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> rejectFriendRequest(AppNotification item) async {
    final requestId = _friendRequestId(item);
    if (requestId == null) return;

    emit(
      state.copyWith(
        actingOn: 'reject:$requestId',
        clearError: true,
        clearActionMessage: true,
      ),
    );

    final result = await _friends.rejectFriendRequest(requestId);
    switch (result) {
      case Success():
        await _repository.dismiss(item.id);
        emit(
          state.copyWith(
            clearActing: true,
            items: state.items.where((n) => n.id != item.id).toList(),
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            clearActing: true,
            errorMessage: failure.message,
          ),
        );
    }
  }

  String? _friendRequestId(AppNotification item) {
    if (item.type != AppNotificationType.friendRequest) return null;
    final target = item.target;
    if (target is FriendNotificationTarget) return target.requestId;
    return null;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
