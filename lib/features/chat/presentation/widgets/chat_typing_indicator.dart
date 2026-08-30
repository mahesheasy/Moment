import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class ChatTypingIndicator extends StatefulWidget {
  const ChatTypingIndicator({required this.user, super.key});

  final UserProfile user;

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user.displayName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          MomentAvatar(
            name: widget.user.displayName,
            imageUrl: widget.user.avatarUrl,
            size: 28,
          ),
          const SizedBox(width: 10),
          Text(
            '$firstName is typing',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: ChatTheme.tertiaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                children: List.generate(3, (index) {
                  final phase = (_controller.value * 3 - index).clamp(0.0, 1.0);
                  return Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: ChatTheme.accentPink.withValues(
                        alpha: 0.35 + (phase * 0.65),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
