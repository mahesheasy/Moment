import 'dart:async';

import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:moment/features/notifications/data/datasources/notifications_read_local_cache.dart';
import 'package:moment/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:moment/features/notifications/domain/entities/app_notification.dart';
import 'package:moment/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:moment/features/profile/data/avatar_url_resolver.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(
    this._remote,
    this._readCache,
    this._avatars,
    this._auth,
  );

  final NotificationsRemoteDataSource _remote;
  final NotificationsReadLocalCache _readCache;
  final AvatarUrlResolver _avatars;
  final AuthRepository _auth;

  String? get _userId => _auth.currentUserId;

  @override
  Stream<List<AppNotification>> watchNotifications() async* {
    final userId = _userId;
    if (userId == null) {
      yield const [];
      return;
    }

    yield await _loadFeed(userId);

    yield* _remote.watchFeedChanges(userId).asyncMap((_) async {
      try {
        return await _loadFeed(userId);
      } on Object {
        return const <AppNotification>[];
      }
    });
  }

  Future<List<AppNotification>> _loadFeed(String userId) async {
    final readIds = await _readCache.loadReadIds();
    final dismissedIds = await _readCache.loadDismissedIds();
    final raw = await _remote.fetchFeed(userId);
    final resolved = await Future.wait(raw.map(_resolveAvatars));
    return resolved
        .where((item) => !dismissedIds.contains(item.id))
        .map(
          (item) => item.copyWith(isUnread: !readIds.contains(item.id)),
        )
        .toList();
  }

  Future<AppNotification> _resolveAvatars(AppNotification item) async {
    final avatarUrl = await _avatars.resolve(item.avatarUrl);
    return AppNotification(
      id: item.id,
      type: item.type,
      title: item.title,
      body: item.body,
      createdAt: item.createdAt,
      isUnread: item.isUnread,
      target: item.target,
      avatarName: item.avatarName,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<Result<void>> markRead(String id) async {
    try {
      await _readCache.markRead(id);
      return const Success(null);
    } on Object catch (error) {
      return Failed(UnknownFailure(cause: error));
    }
  }

  @override
  Future<Result<void>> markAllRead() async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      final feed = await _remote.fetchFeed(userId);
      await _readCache.markAllRead(feed.map((item) => item.id));
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> dismiss(String id) async {
    try {
      await _readCache.markDismissed(id);
      return const Success(null);
    } on Object catch (error) {
      return Failed(UnknownFailure(cause: error));
    }
  }
}
