import 'dart:typed_data';

import 'package:moment/core/result/result.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';

abstract class ChatRepository {
  String? get currentUserId;

  Future<Result<List<ChatConversation>>> getInbox();

  Future<Result<String>> getOrCreateConversation(String otherUserId);

  Future<Result<List<ChatMessage>>> getMessages(String conversationId);

  Future<Result<ChatMessage>> sendTextMessage({
    required String conversationId,
    required String body,
    String? replyToMessageId,
  });

  Future<Result<ChatMessage>> sendImageMessage({
    required String conversationId,
    required Uint8List bytes,
    required String mimeType,
    String? replyToMessageId,
  });

  Future<Result<void>> markConversationRead(String conversationId);

  Future<Result<void>> setReaction({
    required String messageId,
    required String emoji,
    String? currentEmoji,
  });

  Future<Result<void>> deleteMessageForMe(String messageId);

  Future<Result<void>> deleteMessageForEveryone(String messageId);

  Future<Result<void>> toggleMessageStar(String messageId, {required bool starred});

  Future<Result<ChatMessage>> editTextMessage({
    required String messageId,
    required String body,
  });

  Stream<List<ChatMessage>> watchMessages(String conversationId);

  Stream<void> watchInboxChanges();

  Stream<Set<String>> watchTypingUserIds(Map<String, String> conversationToOtherUser);

  Stream<bool> watchOtherUserTyping(String conversationId, String otherUserId);

  Future<Result<void>> setTyping(String conversationId, {required bool isTyping});

  Future<Result<void>> setConversationPinned(
    String conversationId, {
    required bool pinned,
  });

  Future<Result<void>> setConversationMuted(
    String conversationId, {
    required bool muted,
  });

  Future<Result<void>> hideConversation(String conversationId);
}
