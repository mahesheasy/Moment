import 'package:equatable/equatable.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

enum ChatMessageType { text, snap, image }

class ChatMessageReplyPreview extends Equatable {
  const ChatMessageReplyPreview({
    required this.id,
    required this.senderId,
    required this.body,
    required this.messageType,
    this.deletedForEveryone = false,
  });

  final String id;
  final String senderId;
  final String body;
  final ChatMessageType messageType;
  final bool deletedForEveryone;

  @override
  List<Object?> get props => [id, senderId, body, messageType, deletedForEveryone];
}

class ChatMessageReaction extends Equatable {
  const ChatMessageReaction({
    required this.userId,
    required this.emoji,
  });

  final String userId;
  final String emoji;

  @override
  List<Object?> get props => [userId, emoji];
}

class ChatConversation extends Equatable {
  const ChatConversation({
    required this.id,
    required this.otherUser,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
  });

  final String id;
  final UserProfile otherUser;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;

  ChatConversation copyWith({
    UserProfile? otherUser,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
  }) {
    return ChatConversation(
      id: id,
      otherUser: otherUser ?? this.otherUser,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    otherUser,
    lastMessagePreview,
    lastMessageAt,
    unreadCount,
    isPinned,
    isMuted,
  ];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.messageType,
    required this.createdAt,
    this.mediaUrl,
    this.readAt,
    this.editedAt,
    this.isMine = false,
    this.isStarred = false,
    this.replyToMessageId,
    this.replyTo,
    this.reactions = const [],
    this.deletedForEveryone = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final ChatMessageType messageType;
  final String? mediaUrl;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? editedAt;
  final bool isMine;
  final bool isStarred;
  final String? replyToMessageId;
  final ChatMessageReplyPreview? replyTo;
  final List<ChatMessageReaction> reactions;
  final bool deletedForEveryone;

  bool get isRead => readAt != null;

  String? reactionEmojiFor(String userId) {
    for (final reaction in reactions) {
      if (reaction.userId == userId) return reaction.emoji;
    }
    return null;
  }

  ChatMessage copyWith({
    List<ChatMessageReaction>? reactions,
    bool? deletedForEveryone,
    String? body,
    DateTime? editedAt,
    bool? isStarred,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      body: body ?? this.body,
      messageType: messageType,
      mediaUrl: mediaUrl,
      createdAt: createdAt,
      readAt: readAt,
      editedAt: editedAt ?? this.editedAt,
      isMine: isMine,
      isStarred: isStarred ?? this.isStarred,
      replyToMessageId: replyToMessageId,
      replyTo: replyTo,
      reactions: reactions ?? this.reactions,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
    );
  }

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    body,
    messageType,
    mediaUrl,
    createdAt,
    readAt,
    editedAt,
    isMine,
    isStarred,
    replyToMessageId,
    replyTo,
    reactions,
    deletedForEveryone,
  ];
}
