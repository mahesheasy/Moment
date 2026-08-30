import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';

class ChatEncryptionBanner extends StatelessWidget {
  const ChatEncryptionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Text(
        'Messages are private and encrypted.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: ChatTheme.tertiaryText.withValues(alpha: 0.85),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
      ),
    );
  }
}
