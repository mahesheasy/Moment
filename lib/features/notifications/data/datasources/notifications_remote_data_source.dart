import 'dart:async';

import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/errors/postgrest_mapper.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';
import 'package:moment/features/notifications/domain/entities/app_notification.dart';
import 'package:moment/features/profile/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _feedLimit = 40;
  static const _friendWindowDays = 14;

  Future<List<AppNotification>> fetchFeed(String userId) async {
    final results = await Future.wait([
      _fetchFriendRequests(userId),
      _fetchReactions(userId),
      _fetchMomentsReceived(userId),
      _fetchPings(userId),
      _fetchChatMessages(userId),
      _fetchAcceptedFriendRequests(userId),
    ]);

    final feed = results.expand((items) => items).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (feed.length > _feedLimit) {
      return feed.take(_feedLimit).toList();
    }
    return feed;
  }

  Stream<void> watchFeedChanges(String userId) {
    return Stream<void>.multi((multi) {
      Timer? pollTimer;
      Timer? debounceTimer;

      void emit() {
        debounceTimer?.cancel();
        debounceTimer = Timer(const Duration(milliseconds: 350), () {
          if (!multi.isClosed) multi.add(null);
        });
      }

      final subscriptions = <StreamSubscription<dynamic>>[];

      void listenSafe(Stream<dynamic> stream) {
        subscriptions.add(
          stream.listen((_) => emit(), onError: (_, _) {}),
        );
      }
      listenSafe(
        _client
            .from('moment_recipients')
            .stream(primaryKey: ['moment_id', 'recipient_id'])
            .eq('recipient_id', userId),
      );
      listenSafe(
        _client
            .from('moment_reactions')
            .stream(primaryKey: ['moment_id', 'user_id']),
      );
      listenSafe(
        _client
            .from('pings')
            .stream(primaryKey: ['id'])
            .eq('recipient_id', userId),
      );
      listenSafe(_client.from('chat_messages').stream(primaryKey: ['id']));
      listenSafe(
        _client
            .from('friend_requests')
            .stream(primaryKey: ['id'])
            .eq('receiver_id', userId),
      );
      listenSafe(
        _client
            .from('friend_requests')
            .stream(primaryKey: ['id'])
            .eq('sender_id', userId),
      );

      pollTimer = Timer.periodic(const Duration(seconds: 45), (_) => emit());

      multi.onCancel = () async {
        debounceTimer?.cancel();
        pollTimer?.cancel();
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };
    });
  }

  Future<List<AppNotification>> _fetchFriendRequests(String userId) async {
    final data = await _client
        .from('friend_requests')
        .select('id, created_at, sender:sender_id(*)')
        .eq('receiver_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (data as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final sender = ProfileModel.fromJson(
        Map<String, dynamic>.from(map['sender'] as Map),
      ).toEntity();
      final requestId = map['id'] as String;
      return AppNotification(
        id: 'friend_request_$requestId',
        type: AppNotificationType.friendRequest,
        title: sender.displayName,
        body: 'sent you a friend request.',
        createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
        isUnread: true,
        target: FriendNotificationTarget(sender.id, requestId: requestId),
        avatarName: sender.displayName,
        avatarUrl: sender.avatarUrl,
      );
    }).toList();
  }

  Future<List<AppNotification>> _fetchReactions(String userId) async {
    final data = await _client
        .from('moment_reactions')
        .select(
          'moment_id, user_id, reaction, created_at, '
          'reactor:user_id(*), moment:moment_id!inner(sender_id)',
        )
        .eq('moment.sender_id', userId)
        .neq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(_feedLimit);

    return (data as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final reactor = ProfileModel.fromJson(
        Map<String, dynamic>.from(map['reactor'] as Map),
      ).toEntity();
      final momentId = map['moment_id'] as String;
      final reactorId = map['user_id'] as String;
      final reaction = ReactionType.fromValue(map['reaction'] as String);
      final emoji = reaction?.emoji ?? '❤️';

      return AppNotification(
        id: 'reaction_${momentId}_$reactorId',
        type: AppNotificationType.reaction,
        title: reactor.displayName,
        body: 'reacted $emoji to your moment.',
        createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
        isUnread: true,
        target: MomentNotificationTarget(momentId),
        avatarName: reactor.displayName,
        avatarUrl: reactor.avatarUrl,
      );
    }).toList();
  }

  Future<List<AppNotification>> _fetchMomentsReceived(String userId) async {
    final data = await _client
        .from('moment_recipients')
        .select(
          'created_at, moment_id, moment:moments(*, sender:sender_id(*))',
        )
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(_feedLimit);

    return (data as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final momentMap = Map<String, dynamic>.from(map['moment'] as Map);
      final sender = ProfileModel.fromJson(
        Map<String, dynamic>.from(momentMap['sender'] as Map),
      ).toEntity();
      final momentId = map['moment_id'] as String;
      final caption = (momentMap['caption'] as String?)?.trim();

      return AppNotification(
        id: 'moment_$momentId',
        type: AppNotificationType.moment,
        title: sender.displayName,
        body: caption?.isNotEmpty == true ? caption! : 'sent you a moment.',
        createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
        isUnread: true,
        target: MomentNotificationTarget(momentId),
        avatarName: sender.displayName,
        avatarUrl: sender.avatarUrl,
      );
    }).toList();
  }

  Future<List<AppNotification>> _fetchPings(String userId) async {
    final data = await _client
        .from('pings')
        .select('id, moment_id, emoji, created_at, sender:sender_id(*)')
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(_feedLimit);

    return (data as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final sender = ProfileModel.fromJson(
        Map<String, dynamic>.from(map['sender'] as Map),
      ).toEntity();
      final pingId = map['id'] as String;
      final emoji = (map['emoji'] as String?)?.trim();
      final momentId = map['moment_id'] as String?;

      return AppNotification(
        id: 'ping_$pingId',
        type: AppNotificationType.ping,
        title: sender.displayName,
        body: 'sent you ${emoji?.isNotEmpty == true ? emoji! : '👋'}.',
        createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
        isUnread: true,
        target: momentId == null
            ? FriendNotificationTarget(sender.id)
            : MomentNotificationTarget(momentId),
        avatarName: sender.displayName,
        avatarUrl: sender.avatarUrl,
      );
    }).toList();
  }

  Future<List<AppNotification>> _fetchChatMessages(String userId) async {
    final data = await _client
        .from('chat_messages')
        .select(
          'id, body, message_type, created_at, sender:sender_id(*)',
        )
        .neq('sender_id', userId)
        .isFilter('read_at', null)
        .order('created_at', ascending: false)
        .limit(_feedLimit);

    return (data as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final sender = ProfileModel.fromJson(
        Map<String, dynamic>.from(map['sender'] as Map),
      ).toEntity();
      final messageId = map['id'] as String;
      final type = ChatMessageType.values.firstWhere(
        (value) => value.name == (map['message_type'] as String? ?? 'text'),
        orElse: () => ChatMessageType.text,
      );
      final preview = switch (type) {
        ChatMessageType.image => 'sent you a photo.',
        ChatMessageType.snap => 'sent you a snap.',
        ChatMessageType.text =>
          (map['body'] as String?)?.trim().isNotEmpty == true
              ? (map['body'] as String).trim()
              : 'sent you a message.',
      };

      return AppNotification(
        id: 'chat_$messageId',
        type: AppNotificationType.chat,
        title: sender.displayName,
        body: preview,
        createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
        isUnread: true,
        target: ChatNotificationTarget(sender.id),
        avatarName: sender.displayName,
        avatarUrl: sender.avatarUrl,
      );
    }).toList();
  }

  Future<List<AppNotification>> _fetchAcceptedFriendRequests(
    String userId,
  ) async {
    final since = DateTime.now()
        .subtract(const Duration(days: _friendWindowDays))
        .toUtc()
        .toIso8601String();

    final data = await _client
        .from('friend_requests')
        .select('id, updated_at, receiver:receiver_id(*)')
        .eq('sender_id', userId)
        .eq('status', 'accepted')
        .gte('updated_at', since)
        .order('updated_at', ascending: false)
        .limit(10);

    return (data as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final accepter = ProfileModel.fromJson(
        Map<String, dynamic>.from(map['receiver'] as Map),
      ).toEntity();
      final requestId = map['id'] as String;
      final acceptedAt = DateTime.parse(map['updated_at'] as String).toUtc();

      return AppNotification(
        id: 'friend_accepted_$requestId',
        type: AppNotificationType.friendJoined,
        title: accepter.displayName,
        body: 'accepted your friend request. Send them your first moment!',
        createdAt: acceptedAt,
        isUnread: true,
        target: FriendNotificationTarget(accepter.id),
        avatarName: accepter.displayName,
        avatarUrl: accepter.avatarUrl,
      );
    }).toList();
  }

  Failure mapError(Object error) => mapPostgrestError(error);
}
