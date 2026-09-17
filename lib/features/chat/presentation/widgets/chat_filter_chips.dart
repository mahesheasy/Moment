import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';

enum ChatInboxFilter { all, friends, circles, groups, requests }

class ChatFilterChips extends StatelessWidget {
  const ChatFilterChips({
    required this.selected,
    required this.onChanged,
    this.requestCount = 0,
    super.key,
  });

  final ChatInboxFilter selected;
  final ValueChanged<ChatInboxFilter> onChanged;
  final int requestCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'All',
            selected: selected == ChatInboxFilter.all,
            onTap: () => onChanged(ChatInboxFilter.all),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Friends',
            selected: selected == ChatInboxFilter.friends,
            onTap: () => onChanged(ChatInboxFilter.friends),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Circles',
            selected: selected == ChatInboxFilter.circles,
            onTap: () => onChanged(ChatInboxFilter.circles),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Groups',
            selected: selected == ChatInboxFilter.groups,
            onTap: () => onChanged(ChatInboxFilter.groups),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Requests',
            selected: selected == ChatInboxFilter.requests,
            badge: requestCount > 0 ? requestCount : null,
            onTap: () => onChanged(ChatInboxFilter.requests),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? ChatTheme.accentPink(context).withValues(alpha: 0.18)
              : const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? ChatTheme.accentPink(context).withValues(alpha: 0.45)
                : ChatTheme.inputBorder(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: selected ? Colors.white : ChatTheme.tertiaryText(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: ChatTheme.accentPink(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge! > 9 ? '9+' : '$badge',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
