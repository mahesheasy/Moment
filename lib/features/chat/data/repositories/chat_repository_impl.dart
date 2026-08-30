import 'dart:typed_data';

import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:moment/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remote, this._auth);

  final ChatRemoteDataSource _remote;
  final AuthRepository _auth;

  String? get _userId => _auth.currentUserId;

  @override
  String? get currentUserId => _userId;

  @override
  Future<Result<List<ChatConversation>>> getInbox() async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.listInbox(userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<String>> getOrCreateConversation(String otherUserId) async {
    if (_userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getOrCreateConversation(otherUserId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<ChatMessage>>> getMessages(String conversationId) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.listMessages(conversationId, userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<ChatMessage>> sendTextMessage({
    required String conversationId,
    required String body,
    String? replyToMessageId,
  }) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        ValidationFailure(message: 'Message cannot be empty'),
      );
    }

    try {
      return Success(
        await _remote.sendMessage(
          conversationId: conversationId,
          senderId: userId,
          body: trimmed,
          replyToMessageId: replyToMessageId,
        ),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<ChatMessage>> sendImageMessage({
    required String conversationId,
    required Uint8List bytes,
    required String mimeType,
    String? replyToMessageId,
  }) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());
    if (bytes.isEmpty) {
      return const Failed(ValidationFailure(message: 'Image is empty'));
    }

    try {
      return Success(
        await _remote.sendImageMessage(
          conversationId: conversationId,
          senderId: userId,
          bytes: bytes,
          mimeType: mimeType,
          replyToMessageId: replyToMessageId,
        ),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> markConversationRead(String conversationId) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.markRead(conversationId, userId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    final userId = _userId;
    if (userId == null) return const Stream.empty();
    return _remote.watchMessages(conversationId, userId);
  }

  @override
  Stream<void> watchInboxChanges() {
    final userId = _userId;
    if (userId == null) return const Stream.empty();
    return _remote.watchInboxChanges(userId);
  }

  @override
  Stream<Set<String>> watchTypingUserIds(
    Map<String, String> conversationToOtherUser,
  ) {
    final userId = _userId;
    if (userId == null) return const Stream.empty();
    return _remote.watchTypingUserIds(
      userId: userId,
      conversationToOtherUser: conversationToOtherUser,
    );
  }

  @override
  Stream<bool> watchOtherUserTyping(
    String conversationId,
    String otherUserId,
  ) {
    return _remote.watchOtherUserTyping(
      conversationId: conversationId,
      otherUserId: otherUserId,
    );
  }

  @override
  Future<Result<void>> setTyping(
    String conversationId, {
    required bool isTyping,
  }) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      if (isTyping) {
        await _remote.setTyping(
          conversationId: conversationId,
          userId: userId,
        );
      } else {
        await _remote.clearTyping(
          conversationId: conversationId,
          userId: userId,
        );
      }
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> setReaction({
    required String messageId,
    required String emoji,
    String? currentEmoji,
  }) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.setReaction(
        messageId: messageId,
        userId: userId,
        emoji: emoji,
        currentEmoji: currentEmoji,
      );
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> deleteMessageForMe(String messageId) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.hideMessageForUser(messageId: messageId, userId: userId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> deleteMessageForEveryone(String messageId) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.deleteMessageForEveryone(
        messageId: messageId,
        userId: userId,
      );
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> toggleMessageStar(
    String messageId, {
    required bool starred,
  }) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.setMessageStarred(
        messageId: messageId,
        userId: userId,
        starred: starred,
      );
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<ChatMessage>> editTextMessage({
    required String messageId,
    required String body,
  }) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        ValidationFailure(message: 'Message cannot be empty'),
      );
    }

    try {
      return Success(
        await _remote.editTextMessage(
          messageId: messageId,
          userId: userId,
          body: trimmed,
        ),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> setConversationPinned(
    String conversationId, {
    required bool pinned,
  }) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.setConversationPinned(
        conversationId: conversationId,
        userId: userId,
        pinned: pinned,
      );
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> setConversationMuted(
    String conversationId, {
    required bool muted,
  }) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.setConversationMuted(
        conversationId: conversationId,
        userId: userId,
        muted: muted,
      );
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> hideConversation(String conversationId) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.hideConversation(
        conversationId: conversationId,
        userId: userId,
      );
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }
}
