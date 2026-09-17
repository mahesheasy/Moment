import 'package:flutter/material.dart';
import 'package:moment/features/chat/domain/entities/chat_entities.dart';
import 'package:moment/features/chat/presentation/theme/chat_typography.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';
import 'package:moment/features/chat/presentation/utils/chat_formatters.dart';

Future<void> showChatMessageInfoSheet({
  required BuildContext context,
  required ChatMessage message,
  required String otherUserName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: MomentSpaceTheme.surfaceElevated(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final sent = ChatFormatters.messageTime(message.createdAt);
      final sentDate = ChatFormatters.dateDivider(message.createdAt);
      final read = message.readAt == null
          ? null
          : ChatFormatters.messageTime(message.readAt!);
      final edited = message.editedAt == null
          ? null
          : ChatFormatters.messageTime(message.editedAt!);

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
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
              const SizedBox(height: 16),
              Text(
                'Message info',
                style: ChatTypography.headerName(
                  color: MomentSpaceTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                label: 'Sent',
                value: '$sentDate at $sent',
              ),
              if (message.isMine) ...[
                _InfoRow(
                  label: 'Read',
                  value: read == null ? 'Not yet' : read,
                ),
              ] else ...[
                _InfoRow(
                  label: 'From',
                  value: otherUserName,
                ),
              ],
              if (edited != null)
                _InfoRow(label: 'Edited', value: edited),
              if (message.reactions.isNotEmpty)
                _InfoRow(
                  label: 'Reactions',
                  value: message.reactions.length.toString(),
                ),
              if (message.isStarred)
                const _InfoRow(label: 'Starred', value: 'Yes'),
            ],
          ),
        ),
      );
    },
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: ChatTypography.inboxSubtitle(
                color: MomentSpaceTheme.textTertiary(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: ChatTypography.sheetAction(
                color: MomentSpaceTheme.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
