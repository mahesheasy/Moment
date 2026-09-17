import 'package:flutter/material.dart';
import 'package:moment/features/chat/presentation/theme/chat_theme.dart';

/// Chat inbox swipe row — circular Pin + More actions (iOS-style).
class ChatInboxSwipeTile extends StatefulWidget {
  const ChatInboxSwipeTile({
    required this.child,
    required this.onTap,
    required this.onPin,
    required this.onMore,
    this.isPinned = false,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onMore;
  final bool isPinned;

  static const actionWidth = 124.0;

  @override
  State<ChatInboxSwipeTile> createState() => _ChatInboxSwipeTileState();
}

class _ChatInboxSwipeTileState extends State<ChatInboxSwipeTile> {
  double _offset = 0;

  void _close() => setState(() => _offset = 0);

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset + details.delta.dx)
          .clamp(-ChatInboxSwipeTile.actionWidth, 0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final open = _offset < -ChatInboxSwipeTile.actionWidth / 2;
    setState(() {
      _offset = open ? -ChatInboxSwipeTile.actionWidth : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _offset < 0;
    final background = ChatTheme.threadBackdrop(context);

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircleSwipeAction(
                      icon: widget.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: widget.isPinned
                          ? const Color(0xFF636366)
                          : const Color(0xFFFF9F0A),
                      onTap: () {
                        _close();
                        widget.onPin();
                      },
                    ),
                    const SizedBox(width: 10),
                    _CircleSwipeAction(
                      icon: Icons.more_vert_rounded,
                      color: const Color(0xFF48484A),
                      onTap: () {
                        _close();
                        widget.onMore();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            onTap: isOpen ? _close : widget.onTap,
            child: Transform.translate(
              offset: Offset(_offset, 0),
              child: ColoredBox(color: background, child: widget.child),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleSwipeAction extends StatelessWidget {
  const _CircleSwipeAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
