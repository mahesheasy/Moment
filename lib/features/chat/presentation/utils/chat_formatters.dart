import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';

abstract final class ChatFormatters {
  static String inboxTime(DateTime time) {
    final now = DateTime.now().toUtc();
    final then = time.toUtc();
    final diff = now.difference(then);
    if (diff.inDays == 0) {
      final local = then.toLocal();
      final hour = local.hour;
      final minute = local.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final h = hour % 12 == 0 ? 12 : hour % 12;
      return '$h:$minute $period';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return relativeTimeAgo(then);
    return '${then.toLocal().month}/${then.toLocal().day}';
  }

  static String messageTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:$minute $period';
  }

  static String dateDivider(DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static String previewFor(ChatMessageType type, String? body) {
    return switch (type) {
      ChatMessageType.image => '📷 Photo',
      ChatMessageType.snap => '📸 Snap',
      ChatMessageType.text => body?.trim().isNotEmpty == true ? body!.trim() : 'Say hi 👋',
    };
  }

  static bool isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  static List<ChatMessage> chronological(List<ChatMessage> messages) {
    final sorted = List<ChatMessage>.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }
}
