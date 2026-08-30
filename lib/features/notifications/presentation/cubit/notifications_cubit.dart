import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/features/notifications/domain/entities/app_notification.dart';
import 'package:moment/features/notifications/domain/repositories/notifications_repository.dart';

enum NotificationsStatus { initial, loading, ready, error }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.filter = AppNotificationFilter.all,
    this.errorMessage,
  });

  final NotificationsStatus status;
  final List<AppNotification> items;
  final AppNotificationFilter filter;
  final String? errorMessage;

  List<AppNotification> get filteredItems =>
      items.where((item) => item.matchesFilter(filter)).toList();

  int get unreadCount => items.where((item) => item.isUnread).length;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    AppNotificationFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, filter, errorMessage];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationsRepository _repository;
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

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
