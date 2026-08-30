import 'package:equatable/equatable.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';

/// Quick emoji reactions (WhatsApp-style).
abstract final class ChatReactionEmojis {
  static const options = ['❤️', '😂', '😮', '😢', '🙏', '👍'];
}

class ChatReplyTarget extends Equatable {
  const ChatReplyTarget({
    required this.messageId,
    required this.senderName,
    required this.preview,
    required this.isMine,
  });

  final String messageId;
  final String senderName;
  final String preview;
  final bool isMine;

  @override
  List<Object?> get props => [messageId, senderName, preview, isMine];
}

String chatMessagePreview(ChatMessage message) {
  if (message.deletedForEveryone) return 'This message was deleted';
  return switch (message.messageType) {
    ChatMessageType.image => message.body.trim().isEmpty ? 'Photo' : message.body,
    ChatMessageType.snap => 'Shared a moment',
    ChatMessageType.text => message.body,
  };
}
