import 'package:flutter/material.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';

/// WhatsApp-style swipe right to reply.
class ChatSwipeToReply extends StatefulWidget {
  const ChatSwipeToReply({
    required this.child,
    required this.onReply,
    super.key,
  });

  final Widget child;
  final VoidCallback onReply;

  @override
  State<ChatSwipeToReply> createState() => _ChatSwipeToReplyState();
}

class _ChatSwipeToReplyState extends State<ChatSwipeToReply> {
  static const _trigger = 48.0;
  static const _maxDrag = 64.0;

  double _drag = 0;
  var _triggered = false;

  void _onDragUpdate(DragUpdateDetails details) {
    final next = (_drag + details.delta.dx).clamp(0.0, _maxDrag);
    if (next != _drag) {
      setState(() => _drag = next);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_drag >= _trigger && !_triggered) {
      _triggered = true;
      widget.onReply();
    }
    setState(() {
      _drag = 0;
      _triggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_drag / _maxDrag).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          if (_drag > 4)
            Positioned(
              left: 4,
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.85 + (progress * 0.15),
                  child: Icon(
                    Icons.reply_rounded,
                    size: 22,
                    color: MomentSpaceTheme.textTertiary(context),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_drag, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
