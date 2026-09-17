import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/chat/presentation/models/moment_timeline_models.dart';
import 'package:moment/features/chat/presentation/theme/chat_typography.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';

class ChatMessageQuote extends StatelessWidget {
  const ChatMessageQuote({
    required this.reply,
    this.isMineBubble = false,
    super.key,
  });

  final MomentReplyPreview reply;
  final bool isMineBubble;

  @override
  Widget build(BuildContext context) {
    final barColor = isMineBubble
        ? Colors.white.withValues(alpha: 0.7)
        : context.mc.accent.withValues(alpha: 0.85);
    final nameColor = isMineBubble
        ? Colors.white.withValues(alpha: 0.9)
        : context.mc.accent;
    final bodyColor = isMineBubble
        ? Colors.white.withValues(alpha: 0.65)
        : MomentSpaceTheme.textTertiary(context).withValues(alpha: 0.9);

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
      decoration: BoxDecoration(
        color: isMineBubble
            ? Colors.white.withValues(alpha: 0.06)
            : MomentSpaceTheme.surfaceElevated(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: barColor, width: 1.5),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${reply.senderName}: ',
              style: ChatTypography.quoteName(color: nameColor).copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: reply.body,
              style: ChatTypography.quoteBody(color: bodyColor).copyWith(
                fontSize: 9,
                height: 1.15,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
