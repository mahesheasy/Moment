import 'dart:async';
import 'dart:typed_data';

import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/errors/postgrest_mapper.dart' show mapPostgrestError;
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/profile/data/avatar_url_resolver.dart';
import 'package:moment/features/profile/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._client, this._avatarResolver);

  final SupabaseClient _client;
  final AvatarUrlResolver _avatarResolver;
  static const _mediaBucket = 'moments';
  static const _uuid = Uuid();

  Future<String> getOrCreateConversation(String otherUserId) async {
    final id = await _client.rpc<String>(
      'get_or_create_chat_conversation',
      params: {'p_other_user_id': otherUserId},
    );
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await _unhideConversation(conversationId: id, userId: userId);
    }
    return id;
  }

  Future<Map<String, Map<String, dynamic>>> _loadConversationSettings(
    String userId,
  ) async {
    final rows = await _client
        .from('chat_conversation_settings')
        .select()
        .eq('user_id', userId);

    return {
      for (final row in rows as List)
        (row as Map)['conversation_id'] as String: Map<String, dynamic>.from(row),
    };
  }

  Future<void> _unhideConversation({
    required String conversationId,
    required String userId,
  }) async {
    await _client.from('chat_conversation_settings').upsert({
      'user_id': userId,
      'conversation_id': conversationId,
      'is_hidden': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,conversation_id');
  }

  Future<void> setConversationPinned({
    required String conversationId,
    required String userId,
    required bool pinned,
  }) async {
    await _client.from('chat_conversation_settings').upsert({
      'user_id': userId,
      'conversation_id': conversationId,
      'is_pinned': pinned,
      'pinned_at': pinned ? DateTime.now().toUtc().toIso8601String() : null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,conversation_id');
  }

  Future<void> setConversationMuted({
    required String conversationId,
    required String userId,
    required bool muted,
  }) async {
    await _client.from('chat_conversation_settings').upsert({
      'user_id': userId,
      'conversation_id': conversationId,
      'is_muted': muted,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,conversation_id');
  }

  Future<void> hideConversation({
    required String conversationId,
    required String userId,
  }) async {
    await _client.rpc<void>(
      'delete_chat_conversation',
      params: {'p_conversation_id': conversationId},
    );
  }

  Future<List<ChatConversation>> listInbox(String userId) async {
    final rows = await _client
        .from('chat_conversations')
        .select()
        .or('participant_low.eq.$userId,participant_high.eq.$userId')
        .order('last_message_at', ascending: false);

    final settingsByConversation = await _loadConversationSettings(userId);
    final conversations = <ChatConversation>[];

    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final conversationId = map['id'] as String;
      final settings = settingsByConversation[conversationId];
      if (settings?['is_hidden'] == true) continue;

      final otherId = map['participant_low'] == userId
          ? map['participant_high'] as String
          : map['participant_low'] as String;

      final profileRow = await _client
          .from('profiles')
          .select(
            'id, username, display_name, avatar_url, bio, created_at, last_seen_at',
          )
          .eq('id', otherId)
          .maybeSingle();
      if (profileRow == null) continue;

      final unread = await _countUnread(conversationId, userId);

      final profile = ProfileModel.fromJson(
        Map<String, dynamic>.from(profileRow as Map),
      ).toEntity();
      final resolvedAvatar = await _avatarResolver.resolve(profile.avatarUrl);

      conversations.add(
        ChatConversation(
          id: conversationId,
          otherUser: profile.copyWith(avatarUrl: resolvedAvatar),
          lastMessagePreview: map['last_message_preview'] as String?,
          lastMessageAt: _parseTime(map['last_message_at']),
          unreadCount: unread,
          isPinned: settings?['is_pinned'] == true,
          isMuted: settings?['is_muted'] == true,
        ),
      );
    }

    conversations.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return conversations;
  }

  Future<int> _countUnread(String conversationId, String userId) async {
    final data = await _client
        .from('chat_messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId)
        .isFilter('read_at', null);
    return (data as List).length;
  }

  static const _messageSelect = '''
id, conversation_id, sender_id, body, message_type, media_url, read_at,
created_at, edited_at, reply_to_message_id, deleted_for_everyone_at,
reply_to:reply_to_message_id (
  id, sender_id, body, message_type, deleted_for_everyone_at
)
''';

  Future<List<ChatMessage>> listMessages(
    String conversationId,
    String userId,
  ) async {
    final data = await _client
        .from('chat_messages')
        .select(_messageSelect)
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    final rows = (data as List).cast<Map<String, dynamic>>();
    return _buildMessages(
      rows: rows,
      userId: userId,
      conversationId: conversationId,
    );
  }

  Future<List<ChatMessage>> _buildMessages({
    required List<Map<String, dynamic>> rows,
    required String userId,
    required String conversationId,
    Set<String>? cachedHiddenIds,
    Set<String>? cachedStarredIds,
  }) async {
    if (rows.isEmpty) return const [];

    final hiddenIds = cachedHiddenIds ?? await _loadHiddenIds(userId);
    final starredIds = cachedStarredIds ?? await _loadStarredIds(userId);

    final messageIds = rows.map((row) => row['id'] as String).toList();
    final reactionRows = await _client
        .from('chat_message_reactions')
        .select('message_id, user_id, emoji')
        .inFilter('message_id', messageIds);

    final reactionsByMessage = <String, List<ChatMessageReaction>>{};
    for (final row in reactionRows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final messageId = map['message_id'] as String;
      reactionsByMessage
          .putIfAbsent(messageId, () => [])
          .add(
            ChatMessageReaction(
              userId: map['user_id'] as String,
              emoji: map['emoji'] as String,
            ),
          );
    }

    final rowById = {
      for (final row in rows) row['id'] as String: row,
    };

    final messages = rows
        .where((row) => !hiddenIds.contains(row['id'] as String))
        .map(
          (row) => _mapMessage(
            row,
            userId,
            reactions: reactionsByMessage[row['id'] as String] ?? const [],
            rowById: rowById,
            isStarred: starredIds.contains(row['id'] as String),
          ),
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return messages;
  }

  ChatMessageReplyPreview? _replyPreviewFromRow(
    Map<String, dynamic> row, {
    bool deletedOverride = false,
  }) {
    final deleted = deletedOverride || row['deleted_for_everyone_at'] != null;
    return ChatMessageReplyPreview(
      id: row['id'] as String,
      senderId: row['sender_id'] as String,
      body: deleted ? '' : (row['body'] as String? ?? ''),
      messageType: ChatMessageType.values.firstWhere(
        (t) => t.name == (row['message_type'] as String? ?? 'text'),
        orElse: () => ChatMessageType.text,
      ),
      deletedForEveryone: deleted,
    );
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
    ChatMessageType type = ChatMessageType.text,
    String? mediaUrl,
    String? replyToMessageId,
  }) async {
    final inserted = await _client
        .from('chat_messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'body': body,
          'message_type': type.name,
          if (mediaUrl != null) 'media_url': mediaUrl,
          if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
        })
        .select(_messageSelect)
        .single();

    return _mapMessage(
      Map<String, dynamic>.from(inserted as Map),
      senderId,
    );
  }

  Future<String> uploadChatImage({
    required String userId,
    required String conversationId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final extension = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final storagePath =
        '$userId/chat/$conversationId/${_uuid.v4()}.$extension';

    await _client.storage.from(_mediaBucket).uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: false),
    );

    return storagePath;
  }

  Future<ChatMessage> sendImageMessage({
    required String conversationId,
    required String senderId,
    required Uint8List bytes,
    required String mimeType,
    String? replyToMessageId,
  }) async {
    final storagePath = await uploadChatImage(
      userId: senderId,
      conversationId: conversationId,
      bytes: bytes,
      mimeType: 'image/jpeg',
    );

    return sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      body: '',
      type: ChatMessageType.image,
      mediaUrl: storagePath,
      replyToMessageId: replyToMessageId,
    );
  }

  Future<void> setReaction({
    required String messageId,
    required String userId,
    required String emoji,
    String? currentEmoji,
  }) async {
    if (currentEmoji == emoji) {
      await _client.from('chat_message_reactions').delete().match({
        'message_id': messageId,
        'user_id': userId,
      });
      return;
    }

    await _client.from('chat_message_reactions').upsert({
      'message_id': messageId,
      'user_id': userId,
      'emoji': emoji,
    });
  }

  Future<void> hideMessageForUser({
    required String messageId,
    required String userId,
  }) async {
    await _client.from('chat_message_hidden').upsert(
      {
        'message_id': messageId,
        'user_id': userId,
      },
      onConflict: 'message_id,user_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> deleteMessageForEveryone({
    required String messageId,
    required String userId,
  }) async {
    await _client
        .from('chat_messages')
        .update({
          'deleted_for_everyone_at':
              DateTime.now().toUtc().toIso8601String(),
          'body': '',
          'media_url': null,
        })
        .eq('id', messageId)
        .eq('sender_id', userId);
  }

  Future<void> setMessageStarred({
    required String messageId,
    required String userId,
    required bool starred,
  }) async {
    if (starred) {
      await _client.from('chat_message_stars').upsert({
        'message_id': messageId,
        'user_id': userId,
      });
      return;
    }

    await _client.from('chat_message_stars').delete().match({
      'message_id': messageId,
      'user_id': userId,
    });
  }

  Future<ChatMessage> editTextMessage({
    required String messageId,
    required String userId,
    required String body,
  }) async {
    final updated = await _client
        .from('chat_messages')
        .update({
          'body': body,
          'edited_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', messageId)
        .eq('sender_id', userId)
        .isFilter('read_at', null)
        .select(_messageSelect)
        .single();

    return _mapMessage(
      Map<String, dynamic>.from(updated as Map),
      userId,
    );
  }

  Future<void> markRead(String conversationId, String userId) async {
    await _client
        .from('chat_messages')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId)
        .isFilter('read_at', null);
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId, String userId) {
    List<Map<String, dynamic>> lastRows = [];
    Set<String> cachedHiddenIds = {};
    Set<String> cachedStarredIds = {};
    Timer? reactionDebounce;

    Future<void> emitRows(void Function(List<ChatMessage>) onData) async {
      if (lastRows.isEmpty) return;

      final messages = await _buildMessages(
        rows: lastRows,
        userId: userId,
        conversationId: conversationId,
        cachedHiddenIds: cachedHiddenIds,
        cachedStarredIds: cachedStarredIds,
      );
      onData(messages);
    }

    return Stream<List<ChatMessage>>.multi((multi) {
      StreamSubscription<List<Map<String, dynamic>>>? messagesSub;
      StreamSubscription<List<Map<String, dynamic>>>? reactionsSub;
      StreamSubscription<List<Map<String, dynamic>>>? starsSub;

      messagesSub = _client
          .from('chat_messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at')
          .listen(
            (rows) async {
              lastRows = rows;
              cachedHiddenIds = await _loadHiddenIds(userId);
              cachedStarredIds = await _loadStarredIds(userId);
              emitRows(multi.add);
            },
            onError: multi.addError,
          );

      reactionsSub = _client
          .from('chat_message_reactions')
          .stream(primaryKey: ['message_id', 'user_id'])
          .listen(
            (_) {
              reactionDebounce?.cancel();
              reactionDebounce = Timer(
                const Duration(milliseconds: 80),
                () => emitRows(multi.add),
              );
            },
            onError: (_) {},
          );

      final hiddenSub = _client
          .from('chat_message_hidden')
          .stream(primaryKey: ['message_id', 'user_id'])
          .listen(
            (rows) {
              cachedHiddenIds = rows
                  .where((row) => row['user_id'] == userId)
                  .map((row) => row['message_id'] as String)
                  .toSet();
              emitRows(multi.add);
            },
            onError: (_) {},
          );

      starsSub = _client
          .from('chat_message_stars')
          .stream(primaryKey: ['message_id', 'user_id'])
          .eq('user_id', userId)
          .listen(
            (rows) {
              cachedStarredIds = rows
                  .map((row) => row['message_id'] as String)
                  .toSet();
              emitRows(multi.add);
            },
            onError: (_) {},
          );

      multi.onCancel = () async {
        reactionDebounce?.cancel();
        await messagesSub?.cancel();
        await reactionsSub?.cancel();
        await hiddenSub.cancel();
        await starsSub?.cancel();
      };
    });
  }

  Future<Set<String>> _loadHiddenIds(String userId) async {
    final hiddenRows = await _client
        .from('chat_message_hidden')
        .select('message_id')
        .eq('user_id', userId);
    return (hiddenRows as List)
        .map((row) => (row as Map)['message_id'] as String)
        .toSet();
  }

  Future<Set<String>> _loadStarredIds(String userId) async {
    final rows = await _client
        .from('chat_message_stars')
        .select('message_id')
        .eq('user_id', userId);
    return (rows as List)
        .map((row) => (row as Map)['message_id'] as String)
        .toSet();
  }

  ChatMessage _mapMessage(
    Map<String, dynamic> json,
    String userId, {
    List<ChatMessageReaction> reactions = const [],
    Map<String, Map<String, dynamic>>? rowById,
    bool isStarred = false,
  }) {
    final senderId = json['sender_id'] as String;
    final deletedForEveryone = json['deleted_for_everyone_at'] != null;
    final replyRaw = json['reply_to'];
    ChatMessageReplyPreview? replyTo;

    if (replyRaw is Map) {
      final replyMap = Map<String, dynamic>.from(replyRaw);
      replyTo = _replyPreviewFromRow(replyMap);
    } else {
      final parentId = json['reply_to_message_id'] as String?;
      if (parentId != null && rowById != null) {
        final parent = rowById[parentId];
        if (parent != null) {
          replyTo = _replyPreviewFromRow(parent);
        }
      }
    }

    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: senderId,
      body: deletedForEveryone ? '' : (json['body'] as String? ?? ''),
      messageType: ChatMessageType.values.firstWhere(
        (t) => t.name == (json['message_type'] as String? ?? 'text'),
        orElse: () => ChatMessageType.text,
      ),
      mediaUrl: deletedForEveryone ? null : json['media_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String).toUtc(),
      editedAt: json['edited_at'] == null
          ? null
          : DateTime.parse(json['edited_at'] as String).toUtc(),
      isMine: senderId == userId,
      isStarred: isStarred,
      replyToMessageId: json['reply_to_message_id'] as String?,
      replyTo: replyTo,
      reactions: reactions,
      deletedForEveryone: deletedForEveryone,
    );
  }

  Stream<void> watchInboxChanges(String userId) {
    return Stream<void>.multi((multi) {
      Timer? debounce;

      void emit() {
        debounce?.cancel();
        debounce = Timer(const Duration(milliseconds: 280), () {
          if (!multi.isClosed) multi.add(null);
        });
      }

      final subscriptions = <StreamSubscription<dynamic>>[
        _client
            .from('chat_conversations')
            .stream(primaryKey: ['id'])
            .listen((rows) {
              final relevant = rows.any(
                (row) =>
                    row['participant_low'] == userId ||
                    row['participant_high'] == userId,
              );
              if (relevant) emit();
            }),
        _client
            .from('chat_messages')
            .stream(primaryKey: ['id'])
            .listen((_) => emit()),
        _client
            .from('chat_conversation_settings')
            .stream(primaryKey: ['user_id', 'conversation_id'])
            .listen((rows) {
              final relevant = rows.any((row) => row['user_id'] == userId);
              if (relevant) emit();
            }),
      ];

      multi.onCancel = () async {
        debounce?.cancel();
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };
    });
  }

  Future<void> setTyping({
    required String conversationId,
    required String userId,
  }) async {
    await _client.from('chat_typing').upsert({
      'conversation_id': conversationId,
      'user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> clearTyping({
    required String conversationId,
    required String userId,
  }) async {
    await _client.from('chat_typing').delete().match({
      'conversation_id': conversationId,
      'user_id': userId,
    });
  }

  Stream<Set<String>> watchTypingUserIds({
    required String userId,
    required Map<String, String> conversationToOtherUser,
  }) {
    return _client
        .from('chat_typing')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .map((rows) => _mapTypingUserIds(
              rows: rows,
              userId: userId,
              conversationToOtherUser: conversationToOtherUser,
            ));
  }

  Stream<bool> watchOtherUserTyping({
    required String conversationId,
    required String otherUserId,
  }) {
    return _client
        .from('chat_typing')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .map((rows) {
          final now = DateTime.now().toUtc();
          for (final row in rows) {
            if (row['conversation_id'] != conversationId) continue;
            if (row['user_id'] != otherUserId) continue;
            final updatedAt = row['updated_at'] as String?;
            if (updatedAt == null) return true;
            final updated = DateTime.parse(updatedAt).toUtc();
            if (now.difference(updated) <= const Duration(seconds: 6)) {
              return true;
            }
          }
          return false;
        });
  }

  Set<String> _mapTypingUserIds({
    required List<Map<String, dynamic>> rows,
    required String userId,
    required Map<String, String> conversationToOtherUser,
  }) {
    final now = DateTime.now().toUtc();
    final typing = <String>{};

    for (final row in rows) {
      final conversationId = row['conversation_id'] as String?;
      final typingUserId = row['user_id'] as String?;
      if (conversationId == null || typingUserId == null) continue;
      if (typingUserId == userId) continue;
      if (conversationToOtherUser[conversationId] != typingUserId) continue;

      final updatedAt = row['updated_at'] as String?;
      if (updatedAt == null) {
        typing.add(typingUserId);
        continue;
      }
      final updated = DateTime.parse(updatedAt).toUtc();
      if (now.difference(updated) <= const Duration(seconds: 6)) {
        typing.add(typingUserId);
      }
    }

    return typing;
  }

  DateTime? _parseTime(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.parse(value).toUtc();
  }

  Failure mapError(Object error) => mapPostgrestError(error);
}
