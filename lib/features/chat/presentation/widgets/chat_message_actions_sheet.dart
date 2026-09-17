import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/presentation/theme/chat_typography.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';
import 'package:moment/features/chat/presentation/utils/chat_message_actions.dart';
import 'package:moment/features/chat/presentation/widgets/chat_emoji_picker_sheet.dart';

enum ChatMessageSheetAction {
  reply,
  react,
  star,
  edit,
  info,
  copy,
  deleteForMe,
  deleteForEveryone,
}

Future<ChatMessageSheetAction?> showChatMessageActionsSheet({
  required BuildContext context,
  required ChatMessage message,
  required String previewText,
  void Function(String emoji)? onQuickReact,
}) {
  return showModalBottomSheet<ChatMessageSheetAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MomentSpaceTheme.surfaceElevated(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (!message.deletedForEveryone) ...[
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final emoji in ChatReactionEmojis.options)
                        _EmojiChip(
                          emoji: emoji,
                          onTap: () {
                            Navigator.pop(context);
                            onQuickReact?.call(emoji);
                          },
                        ),
                      _EmojiChip(
                        emoji: '➕',
                        size: 20,
                        onTap: () async {
                          Navigator.pop(context);
                          final picked = await showChatEmojiPicker(context);
                          if (picked != null) onQuickReact?.call(picked);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 4),
              ],
              _ActionTile(
                icon: Icons.reply_rounded,
                label: 'Reply',
                onTap: () => Navigator.pop(context, ChatMessageSheetAction.reply),
              ),
              if (!message.deletedForEveryone)
                _ActionTile(
                  icon: message.isStarred
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  label: message.isStarred ? 'Unstar' : 'Star',
                  onTap: () => Navigator.pop(context, ChatMessageSheetAction.star),
                ),
              if (!message.deletedForEveryone)
                _ActionTile(
                  icon: Icons.add_reaction_outlined,
                  label: 'React',
                  onTap: () =>
                      Navigator.pop(context, ChatMessageSheetAction.react),
                ),
              if (message.canEdit)
                _ActionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () => Navigator.pop(context, ChatMessageSheetAction.edit),
                ),
              if (!message.deletedForEveryone)
                _ActionTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Message info',
                  onTap: () => Navigator.pop(context, ChatMessageSheetAction.info),
                ),
              if (!message.deletedForEveryone && previewText.isNotEmpty)
                _ActionTile(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  onTap: () =>
                      Navigator.pop(context, ChatMessageSheetAction.copy),
                ),
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete for me',
                destructive: true,
                onTap: () =>
                    Navigator.pop(context, ChatMessageSheetAction.deleteForMe),
              ),
              if (message.isMine && !message.deletedForEveryone)
                _ActionTile(
                  icon: Icons.delete_forever_outlined,
                  label: 'Delete for everyone',
                  destructive: true,
                  onTap: () => Navigator.pop(
                    context,
                    ChatMessageSheetAction.deleteForEveryone,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> showChatReactionPicker(BuildContext context) {
  return showChatEmojiPicker(context);
}

Future<void> copyChatMessageText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Copied to clipboard'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({
    required this.emoji,
    required this.onTap,
    this.size = 28,
  });

  final String emoji;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: MomentSpaceTheme.composerPillBackground(context),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: size)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFFF6B6B)
        : MomentSpaceTheme.textPrimary(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label, style: ChatTypography.sheetAction(color: color)),
          ],
        ),
      ),
    );
  }
}
