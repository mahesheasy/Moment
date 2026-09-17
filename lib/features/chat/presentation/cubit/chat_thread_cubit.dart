import 'dart:async';

import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/domain/repositories/chat_repository.dart';
import 'package:moment/features/chat/presentation/utils/chat_formatters.dart';
import 'package:moment/features/chat/presentation/utils/chat_message_actions.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

enum ChatThreadStatus { initial, loading, ready, sending, error }

class ChatEditTarget extends Equatable {
  const ChatEditTarget({
    required this.messageId,
    required this.originalBody,
  });

  final String messageId;
  final String originalBody;

  @override
  List<Object?> get props => [messageId, originalBody];
}

class ChatThreadState extends Equatable {
  const ChatThreadState({
    this.status = ChatThreadStatus.initial,
    this.otherUser,
    this.conversationId,
    this.messages = const [],
    this.otherUserTyping = false,
    this.replyTo,
    this.editingMessage,
    this.errorMessage,
    this.relationship = FriendRelationship.none,
    this.isActingOnRelationship = false,
    this.hasCompletedInitialLoad = false,
    this.reportAcknowledged = false,
  });

  final ChatThreadStatus status;
  final UserProfile? otherUser;
  final String? conversationId;
  final List<ChatMessage> messages;
  final bool otherUserTyping;
  final ChatReplyTarget? replyTo;
  final ChatEditTarget? editingMessage;
  final String? errorMessage;
  final FriendRelationship relationship;
  final bool isActingOnRelationship;
  final bool hasCompletedInitialLoad;
  final bool reportAcknowledged;

  bool get isBlocked =>
      relationship == FriendRelationship.blocked ||
      relationship == FriendRelationship.blockedBy;

  bool get canSendMessages => relationship == FriendRelationship.friends;

  bool get isRestricted =>
      hasCompletedInitialLoad && !canSendMessages && !isBlocked;

  ChatThreadState copyWith({
    ChatThreadStatus? status,
    UserProfile? otherUser,
    String? conversationId,
    List<ChatMessage>? messages,
    bool? otherUserTyping,
    ChatReplyTarget? replyTo,
    ChatEditTarget? editingMessage,
    String? errorMessage,
    FriendRelationship? relationship,
    bool? isActingOnRelationship,
    bool? hasCompletedInitialLoad,
    bool? reportAcknowledged,
    bool clearError = false,
    bool clearReply = false,
    bool clearEditing = false,
  }) {
    return ChatThreadState(
      status: status ?? this.status,
      otherUser: otherUser ?? this.otherUser,
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      otherUserTyping: otherUserTyping ?? this.otherUserTyping,
      replyTo: clearReply ? null : replyTo ?? this.replyTo,
      editingMessage:
          clearEditing ? null : editingMessage ?? this.editingMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      relationship: relationship ?? this.relationship,
      isActingOnRelationship:
          isActingOnRelationship ?? this.isActingOnRelationship,
      hasCompletedInitialLoad:
          hasCompletedInitialLoad ?? this.hasCompletedInitialLoad,
      reportAcknowledged: reportAcknowledged ?? this.reportAcknowledged,
    );
  }

  @override
  List<Object?> get props => [
    status,
    otherUser,
    conversationId,
    messages,
    otherUserTyping,
    replyTo,
    editingMessage,
    errorMessage,
    relationship,
    isActingOnRelationship,
    hasCompletedInitialLoad,
    reportAcknowledged,
  ];
}

class ChatThreadCubit extends Cubit<ChatThreadState> {
  ChatThreadCubit(
    this._repository,
    this._friendsRepository,
    this._profileRemote,
    this._otherUser,
  ) : super(ChatThreadState(otherUser: _otherUser, status: ChatThreadStatus.loading));

  final ChatRepository _repository;
  final FriendsRepository _friendsRepository;
  final ProfileRemoteDataSource _profileRemote;
  final UserProfile _otherUser;
  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<bool>? _typingSub;
  StreamSubscription<DateTime?>? _presenceSub;
  Timer? _presencePollTimer;
  Timer? _typingClearTimer;
  var _acceptStreamUpdates = false;

  Future<void> load() async {
    _acceptStreamUpdates = false;
    emit(
      state.copyWith(
        status: ChatThreadStatus.loading,
        messages: const [],
        hasCompletedInitialLoad: false,
        clearError: true,
      ),
    );

    final relationship = await _loadRelationship();

    unawaited(_profileRemote.touchLastSeen());
    await _startPresenceWatch();

    if (relationship != FriendRelationship.friends) {
      if (relationship != FriendRelationship.blocked &&
          relationship != FriendRelationship.blockedBy) {
        emit(
          state.copyWith(
            status: ChatThreadStatus.ready,
            relationship: relationship,
            hasCompletedInitialLoad: true,
            messages: const [],
            clearError: true,
          ),
        );
        return;
      }
    }

    final conversationResult = await _repository.getOrCreateConversation(
      _otherUser.id,
    );
    if (conversationResult is Failed) {
      final message = conversationResult.failureOrNull?.message ?? '';
      final isFriendsOnly = message.toLowerCase().contains(
        'only chat with friends',
      );
      emit(
        state.copyWith(
          status: isFriendsOnly
              ? ChatThreadStatus.ready
              : ChatThreadStatus.error,
          relationship: isFriendsOnly
              ? FriendRelationship.none
              : relationship,
          hasCompletedInitialLoad: true,
          messages: const [],
          clearError: isFriendsOnly,
          errorMessage: isFriendsOnly ? null : message,
        ),
      );
      return;
    }

    final conversationId =
        (conversationResult as Success<String>).value;

    final messagesResult = await _repository.getMessages(conversationId);
    if (messagesResult is Failed) {
      emit(
        state.copyWith(
          status: ChatThreadStatus.error,
          relationship: relationship,
          conversationId: conversationId,
          hasCompletedInitialLoad: true,
          errorMessage: messagesResult.failureOrNull?.message,
        ),
      );
      return;
    }

    await _repository.markConversationRead(conversationId);

    await _messagesSub?.cancel();
    _messagesSub = _repository.watchMessages(conversationId).listen(
      (messages) {
        if (isClosed || !_acceptStreamUpdates) return;
        emit(
          state.copyWith(
            status: ChatThreadStatus.ready,
            conversationId: conversationId,
            messages: ChatFormatters.chronological(messages),
          ),
        );
        unawaited(_repository.markConversationRead(conversationId));
      },
      onError: (_) {},
    );

    await _typingSub?.cancel();
    _typingSub = _repository
        .watchOtherUserTyping(conversationId, _otherUser.id)
        .listen(
          (typing) {
            if (isClosed) return;
            emit(state.copyWith(otherUserTyping: typing));
          },
          onError: (_) {},
        );

    emit(
      state.copyWith(
        status: ChatThreadStatus.ready,
        conversationId: conversationId,
        relationship: relationship,
        hasCompletedInitialLoad: true,
        messages: ChatFormatters.chronological(
          (messagesResult as Success<List<ChatMessage>>).value,
        ),
      ),
    );
    _acceptStreamUpdates = true;
  }

  Future<void> _startPresenceWatch() async {
    await _presenceSub?.cancel();
    _presencePollTimer?.cancel();

    await _refreshOtherUserPresence();

    _presenceSub = _profileRemote.watchLastSeen(_otherUser.id).listen(
      (lastSeenAt) {
        if (isClosed || lastSeenAt == null) return;
        _applyLastSeen(lastSeenAt);
      },
      onError: (_) {},
    );

    _presencePollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_refreshOtherUserPresence()),
    );
  }

  Future<void> _refreshOtherUserPresence() async {
    try {
      final lastSeenAt = await _profileRemote.fetchLastSeen(_otherUser.id);
      if (isClosed) return;
      if (lastSeenAt != null) {
        _applyLastSeen(lastSeenAt);
        return;
      }

      final profile = await _profileRemote.getProfile(_otherUser.id);
      if (!isClosed) {
        emit(state.copyWith(otherUser: profile));
      }
    } on Object {
      // Keep the profile passed into the thread if refresh fails.
    }
  }

  void _applyLastSeen(DateTime lastSeenAt) {
    final current = state.otherUser ?? _otherUser;
    if (current.lastSeenAt == lastSeenAt) return;
    emit(state.copyWith(otherUser: current.copyWith(lastSeenAt: lastSeenAt)));
  }

  Future<FriendRelationship> _loadRelationship() async {
    final result = await _friendsRepository.getRelationship(_otherUser.id);
    if (result is Success<FriendRelationship>) {
      return result.value;
    }
    return FriendRelationship.none;
  }

  Future<void> refreshRelationship() async {
    final relationship = await _loadRelationship();
    emit(state.copyWith(relationship: relationship, clearReply: true));
  }

  void onUserReported() {
    emit(
      state.copyWith(
        status: ChatThreadStatus.ready,
        reportAcknowledged: true,
        messages: const [],
        clearError: true,
        clearReply: true,
      ),
    );
  }

  Future<void> blockUser() async {
    emit(state.copyWith(isActingOnRelationship: true, clearError: true));
    final result = await _friendsRepository.blockUser(_otherUser.id);
    if (result is Failed && !isClosed) {
      emit(
        state.copyWith(
          isActingOnRelationship: false,
          errorMessage: result.failureOrNull?.message,
        ),
      );
      return;
    }
    await refreshRelationship();
    if (!isClosed) {
      emit(state.copyWith(isActingOnRelationship: false));
    }
  }

  Future<void> unblockUser() async {
    emit(state.copyWith(isActingOnRelationship: true, clearError: true));
    final result = await _friendsRepository.unblockUser(_otherUser.id);
    if (result is Failed && !isClosed) {
      emit(
        state.copyWith(
          isActingOnRelationship: false,
          errorMessage: result.failureOrNull?.message,
        ),
      );
      return;
    }
    await refreshRelationship();
    if (!isClosed) {
      emit(state.copyWith(isActingOnRelationship: false));
    }
  }

  void onComposerChanged(String text) {
    if (state.isBlocked) return;
    final conversationId = state.conversationId;
    if (conversationId == null) return;

    if (text.trim().isEmpty) {
      _typingClearTimer?.cancel();
      unawaited(_repository.setTyping(conversationId, isTyping: false));
      return;
    }

    unawaited(_repository.setTyping(conversationId, isTyping: true));
    _typingClearTimer?.cancel();
    _typingClearTimer = Timer(const Duration(seconds: 4), () {
      unawaited(_repository.setTyping(conversationId, isTyping: false));
    });
  }

  Future<void> sendMessage(String body) async {
    if (state.isBlocked) return;
    final conversationId = state.conversationId;
    if (conversationId == null || body.trim().isEmpty) return;

    _typingClearTimer?.cancel();
    unawaited(_repository.setTyping(conversationId, isTyping: false));

    final replyId = state.replyTo?.messageId;

    emit(
      state.copyWith(
        clearError: true,
        clearReply: true,
        clearEditing: true,
      ),
    );
    final result = await _repository.sendTextMessage(
      conversationId: conversationId,
      body: body,
      replyToMessageId: replyId,
    );

    if (result is Failed) {
      emit(
        state.copyWith(
          status: ChatThreadStatus.ready,
          errorMessage: result.failureOrNull?.message,
        ),
      );
      return;
    }

    emit(state.copyWith(status: ChatThreadStatus.ready));
  }

  Future<void> sendImage({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (state.isBlocked) return;
    final conversationId = state.conversationId;
    if (conversationId == null || bytes.isEmpty) return;

    final replyId = state.replyTo?.messageId;

    emit(
      state.copyWith(
        status: ChatThreadStatus.sending,
        clearError: true,
        clearReply: true,
      ),
    );
    final result = await _repository.sendImageMessage(
      conversationId: conversationId,
      bytes: bytes,
      mimeType: mimeType,
      replyToMessageId: replyId,
    );

    if (result is Failed) {
      emit(
        state.copyWith(
          status: ChatThreadStatus.ready,
          errorMessage: result.failureOrNull?.message,
        ),
      );
      return;
    }

    emit(state.copyWith(status: ChatThreadStatus.ready));
  }

  void setReplyTo(ChatMessage message) {
    final otherName = _otherUser.displayName;
    emit(
      state.copyWith(
        clearEditing: true,
        replyTo: ChatReplyTarget(
          messageId: message.id,
          senderName: message.isMine ? 'You' : otherName,
          preview: chatMessagePreview(message),
          isMine: message.isMine,
        ),
      ),
    );
  }

  void clearReply() => emit(state.copyWith(clearReply: true));

  void setEditTo(ChatMessage message) {
    if (!message.canEdit) return;
    emit(
      state.copyWith(
        clearReply: true,
        editingMessage: ChatEditTarget(
          messageId: message.id,
          originalBody: message.body,
        ),
      ),
    );
  }

  void clearEdit() => emit(state.copyWith(clearEditing: true));

  Future<void> reactToMessage(String messageId, String emoji) async {
    final userId = _repository.currentUserId;
    if (userId == null) return;

    final message = messageById(messageId);
    if (message == null) return;

    final currentEmoji = message.reactionEmojiFor(userId);
    final nextReactions = List<ChatMessageReaction>.from(message.reactions)
      ..removeWhere((reaction) => reaction.userId == userId);
    if (currentEmoji != emoji) {
      nextReactions.add(ChatMessageReaction(userId: userId, emoji: emoji));
    }

    emit(
      state.copyWith(
        messages: state.messages
            .map(
              (item) => item.id == messageId
                  ? item.copyWith(reactions: nextReactions)
                  : item,
            )
            .toList(),
      ),
    );

    final result = await _repository.setReaction(
      messageId: messageId,
      emoji: emoji,
      currentEmoji: currentEmoji,
    );
    if (result is Failed && !isClosed) {
      emit(
        state.copyWith(errorMessage: result.failureOrNull?.message),
      );
    }
  }

  Future<void> deleteMessageForMe(String messageId) async {
    final result = await _repository.deleteMessageForMe(messageId);
    if (result is Failed && !isClosed) {
      emit(state.copyWith(errorMessage: result.failureOrNull?.message));
      return;
    }
    emit(
      state.copyWith(
        messages: state.messages.where((m) => m.id != messageId).toList(),
      ),
    );
  }

  Future<void> deleteMessageForEveryone(String messageId) async {
    emit(
      state.copyWith(
        messages: state.messages
            .map(
              (message) => message.id == messageId
                  ? message.copyWith(
                      deletedForEveryone: true,
                      body: '',
                    )
                  : message,
            )
            .toList(),
      ),
    );

    final result = await _repository.deleteMessageForEveryone(messageId);
    if (result is Failed && !isClosed) {
      emit(state.copyWith(errorMessage: result.failureOrNull?.message));
    }
  }

  Future<void> toggleMessageStar(String messageId) async {
    final message = messageById(messageId);
    if (message == null) return;

    final nextStarred = !message.isStarred;
    emit(
      state.copyWith(
        messages: state.messages
            .map(
              (item) => item.id == messageId
                  ? item.copyWith(isStarred: nextStarred)
                  : item,
            )
            .toList(),
      ),
    );

    final result = await _repository.toggleMessageStar(
      messageId,
      starred: nextStarred,
    );
    if (result is Failed && !isClosed) {
      emit(
        state.copyWith(
          messages: state.messages
              .map(
                (item) => item.id == messageId
                    ? item.copyWith(isStarred: message.isStarred)
                    : item,
              )
              .toList(),
          errorMessage: result.failureOrNull?.message,
        ),
      );
    }
  }

  Future<void> editMessage(String messageId, String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final message = messageById(messageId);
    if (message == null || !message.canEdit) return;
    if (trimmed == message.body) {
      emit(state.copyWith(clearEditing: true));
      return;
    }

    final optimisticEditedAt = DateTime.now().toUtc();
    emit(
      state.copyWith(
        clearEditing: true,
        messages: state.messages
            .map(
              (item) => item.id == messageId
                  ? item.copyWith(body: trimmed, editedAt: optimisticEditedAt)
                  : item,
            )
            .toList(),
      ),
    );

    final result = await _repository.editTextMessage(
      messageId: messageId,
      body: trimmed,
    );
    if (result is Failed && !isClosed) {
      emit(
        state.copyWith(
          messages: state.messages
              .map((item) => item.id == messageId ? message : item)
              .toList(),
          errorMessage: result.failureOrNull?.message,
        ),
      );
      return;
    }

    final updated = (result as Success<ChatMessage>).value;
    emit(
      state.copyWith(
        messages: state.messages
            .map((item) => item.id == messageId ? updated : item)
            .toList(),
      ),
    );
  }

  String? get currentUserId => _repository.currentUserId;

  ChatMessage? messageById(String id) {
    for (final message in state.messages) {
      if (message.id == id) return message;
    }
    return null;
  }

  @override
  Future<void> close() async {
    _acceptStreamUpdates = false;
    _typingClearTimer?.cancel();
    _presencePollTimer?.cancel();
    final conversationId = state.conversationId;
    if (conversationId != null) {
      unawaited(_repository.setTyping(conversationId, isTyping: false));
    }
    await _typingSub?.cancel();
    await _presenceSub?.cancel();
    await _messagesSub?.cancel();
    return super.close();
  }
}
