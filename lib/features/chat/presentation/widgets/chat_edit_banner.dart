import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';

class ChatEditBanner extends StatelessWidget {
  const ChatEditBanner({
    required this.onClose,
    super.key,
  });

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: MomentSpaceTheme.composerBarBackground(context),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_outlined,
            size: 16,
            color: context.mc.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editing message',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.mc.accent,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: MomentSpaceTheme.textTertiary(context),
            ),
          ),
        ],
      ),
    );
  }
}
