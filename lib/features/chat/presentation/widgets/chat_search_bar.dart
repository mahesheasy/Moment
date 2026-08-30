import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';

class ChatSearchBar extends StatefulWidget {
  const ChatSearchBar({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<ChatSearchBar> createState() => _ChatSearchBarState();
}

class _ChatSearchBarState extends State<ChatSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ChatTheme.inputBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ChatTheme.inputBorder),
        ),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search chats',
            hintStyle: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: ChatTheme.tertiaryText,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              AppIcons.search,
              color: ChatTheme.tertiaryText,
              size: 20,
            ),
            suffixIcon: hasText
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: ChatTheme.tertiaryText,
                      size: 18,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }
}
