import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';

class ChatDateDivider extends StatelessWidget {
  const ChatDateDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: ChatTheme.tertiaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
