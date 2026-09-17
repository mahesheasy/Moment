import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onPickImage,
    required this.onCameraTap,
    super.key,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onCameraTap;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  var _hasText = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _onTextChanged();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final next = widget.controller.text.trim().isNotEmpty;
    if (next != _hasText) setState(() => _hasText = next);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isDark = context.isDarkMode;
    final canSend = _hasText && !widget.isSending;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ChatTheme.headerBackground(context),
        border: Border(
          top: BorderSide(
            color: ChatTheme.divider(context).withValues(alpha: isDark ? 1 : 0.6),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: widget.onPickImage,
              icon: Icon(
                Icons.image_outlined,
                color: ChatTheme.secondaryText(context),
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                decoration: BoxDecoration(
                  color: ChatTheme.inputBackground(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    color: ChatTheme.primaryText(context),
                    fontSize: 16,
                    height: 1.3,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: ChatTheme.secondaryText(context),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: canSend ? (_) => widget.onSend() : null,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: canSend ? ChatTheme.sentBubble(context) : Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: canSend ? widget.onSend : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: widget.isSending
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.arrow_upward_rounded,
                          size: 20,
                          color: canSend
                              ? Colors.white
                              : ChatTheme.secondaryText(context)
                                  .withValues(alpha: 0.4),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
