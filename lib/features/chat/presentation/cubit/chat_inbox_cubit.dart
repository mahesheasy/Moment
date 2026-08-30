import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/domain/repositories/chat_repository.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

enum ChatInboxStatus { initial, loading, ready, error }

class ChatInboxState extends Equatable {
  const ChatInboxState({
    this.status = ChatInboxStatus.initial,
    this.conversations = const [],
    this.friendsWithoutChat = const [],
    this.typingUserIds = const {},
    this.errorMessage,
    this.hasCompletedInitialLoad = false,
  });

  final ChatInboxStatus status;
  final List<ChatConversation> conversations;
  final List<UserProfile> friendsWithoutChat;
  final Set<String> typingUserIds;
  final String? errorMessage;
  final bool hasCompletedInitialLoad;

  ChatInboxState copyWith({
    ChatInboxStatus? status,
    List<ChatConversation>? conversations,
    List<UserProfile>? friendsWithoutChat,
    Set<String>? typingUserIds,
    String? errorMessage,
    bool clearError = false,
    bool? hasCompletedInitialLoad,
  }) {
    return ChatInboxState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      friendsWithoutChat: friendsWithoutChat ?? this.friendsWithoutChat,
      typingUserIds: typingUserIds ?? this.typingUserIds,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      hasCompletedInitialLoad:
          hasCompletedInitialLoad ?? this.hasCompletedInitialLoad,
    );
  }

  @override
  List<Object?> get props => [
    status,
    conversations,
    friendsWithoutChat,
    typingUserIds,
    errorMessage,
    hasCompletedInitialLoad,
  ];
}

class ChatInboxCubit extends Cubit<ChatInboxState> {
  ChatInboxCubit(this._chatRepository, this._friendsRepository)
    : super(const ChatInboxState(status: ChatInboxStatus.loading));

  final ChatRepository _chatRepository;
  final FriendsRepository _friendsRepository;

  StreamSubscription<void>? _inboxSub;
  StreamSubscription<Set<String>>? _typingSub;

  Future<void> load() async {
    if (!state.hasCompletedInitialLoad) {
      emit(state.copyWith(status: ChatInboxStatus.loading, clearError: true));
    }
    await _refreshInbox();
    await _subscribeRealtime();
  }

  Future<void> _refreshInbox() async {
    final inboxResult = await _chatRepository.getInbox();
    final friendsResult = await _friendsRepository.getFriends();

    if (inboxResult is Failed) {
      final message = inboxResult.failureOrNull?.message ?? '';
      final friendly = message.contains('chat_conversations')
          ? 'Chat is still setting up. Pull to refresh in a moment.'
          : message;
      emit(
        state.copyWith(
          status: ChatInboxStatus.error,
          errorMessage: friendly.isNotEmpty ? friendly : 'Could not load chats.',
        ),
      );
      return;
    }

    final conversations = (inboxResult as Success<List<ChatConversation>>).value;
    final friends = friendsResult is Success<List<FriendSummary>>
        ? friendsResult.value
        : <FriendSummary>[];

    final chattedIds = conversations.map((c) => c.otherUser.id).toSet();
    final friendsWithoutChat = friends
        .map((f) => f.profile)
        .where((p) => !chattedIds.contains(p.id))
        .toList();

    emit(
      state.copyWith(
        status: ChatInboxStatus.ready,
        conversations: conversations,
        friendsWithoutChat: friendsWithoutChat,
        hasCompletedInitialLoad: true,
      ),
    );

    await _subscribeTyping(conversations);
  }

  Future<void> _subscribeRealtime() async {
    await _inboxSub?.cancel();
    _inboxSub = _chatRepository.watchInboxChanges().listen(
      (_) => _refreshInbox(),
      onError: (_) {},
    );
  }

  Future<void> _subscribeTyping(List<ChatConversation> conversations) async {
    await _typingSub?.cancel();
    if (conversations.isEmpty) {
      emit(state.copyWith(typingUserIds: const {}));
      return;
    }

    final conversationToOtherUser = {
      for (final c in conversations) c.id: c.otherUser.id,
    };

    _typingSub = _chatRepository
        .watchTypingUserIds(conversationToOtherUser)
        .listen(
          (typingUserIds) {
            if (isClosed) return;
            emit(state.copyWith(typingUserIds: typingUserIds));
          },
          onError: (_) {},
        );
  }

  List<ChatConversation> _sortedConversations(
    List<ChatConversation> conversations,
  ) {
    final sorted = List<ChatConversation>.from(conversations);
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  void _updateConversation(
    String conversationId,
    ChatConversation Function(ChatConversation current) update,
  ) {
    final updated = state.conversations
        .map(
          (conversation) => conversation.id == conversationId
              ? update(conversation)
              : conversation,
        )
        .toList();
    emit(state.copyWith(conversations: _sortedConversations(updated)));
  }

  Future<String?> pinConversation(String conversationId) async {
    _updateConversation(
      conversationId,
      (conversation) => conversation.copyWith(isPinned: true),
    );
    final result = await _chatRepository.setConversationPinned(
      conversationId,
      pinned: true,
    );
    if (result is Failed) {
      await _refreshInbox();
      return result.failureOrNull?.message;
    }
    return null;
  }

  Future<String?> unpinConversation(String conversationId) async {
    _updateConversation(
      conversationId,
      (conversation) => conversation.copyWith(isPinned: false),
    );
    final result = await _chatRepository.setConversationPinned(
      conversationId,
      pinned: false,
    );
    if (result is Failed) {
      await _refreshInbox();
      return result.failureOrNull?.message;
    }
    return null;
  }

  Future<String?> muteConversation(String conversationId) async {
    _updateConversation(
      conversationId,
      (conversation) => conversation.copyWith(isMuted: true),
    );
    final result = await _chatRepository.setConversationMuted(
      conversationId,
      muted: true,
    );
    if (result is Failed) {
      await _refreshInbox();
      return result.failureOrNull?.message;
    }
    return null;
  }

  Future<String?> unmuteConversation(String conversationId) async {
    _updateConversation(
      conversationId,
      (conversation) => conversation.copyWith(isMuted: false),
    );
    final result = await _chatRepository.setConversationMuted(
      conversationId,
      muted: false,
    );
    if (result is Failed) {
      await _refreshInbox();
      return result.failureOrNull?.message;
    }
    return null;
  }

  Future<String?> deleteConversation(String conversationId) async {
    final updated = state.conversations
        .where((conversation) => conversation.id != conversationId)
        .toList();
    emit(state.copyWith(conversations: updated));

    final result = await _chatRepository.hideConversation(conversationId);
    if (result is Failed) {
      await _refreshInbox();
      return result.failureOrNull?.message;
    }
    return null;
  }

  Future<FriendRelationship> getRelationship(String userId) async {
    final result = await _friendsRepository.getRelationship(userId);
    if (result is Success<FriendRelationship>) return result.value;
    return FriendRelationship.none;
  }

  Future<String?> blockUser(String userId) async {
    final result = await _friendsRepository.blockUser(userId);
    if (result is Failed) return result.failureOrNull?.message;
    await _refreshInbox();
    return null;
  }

  Future<String?> unblockUser(String userId) async {
    final result = await _friendsRepository.unblockUser(userId);
    if (result is Failed) return result.failureOrNull?.message;
    await _refreshInbox();
    return null;
  }

  @override
  Future<void> close() async {
    await _inboxSub?.cancel();
    await _typingSub?.cancel();
    return super.close();
  }
}
