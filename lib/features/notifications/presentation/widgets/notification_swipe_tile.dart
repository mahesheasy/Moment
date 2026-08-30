import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';

/// Instagram-style swipe row with More + Delete actions behind the content.
class NotificationSwipeTile extends StatefulWidget {
  const NotificationSwipeTile({
    required this.child,
    required this.onTap,
    required this.onMore,
    required this.onDelete,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onMore;
  final VoidCallback onDelete;

  static const actionWidth = 112.0;
  static const buttonWidth = 56.0;

  @override
  State<NotificationSwipeTile> createState() => _NotificationSwipeTileState();
}

class _NotificationSwipeTileState extends State<NotificationSwipeTile> {
  double _offset = 0;

  void _close() => setState(() => _offset = 0);

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset + details.delta.dx)
          .clamp(-NotificationSwipeTile.actionWidth, 0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final open = _offset < -NotificationSwipeTile.actionWidth / 2;
    setState(() {
      _offset = open ? -NotificationSwipeTile.actionWidth : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _offset < 0;

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _SwipeActionButton(
                  width: NotificationSwipeTile.buttonWidth,
                  icon: Icons.more_horiz_rounded,
                  color: const Color(0xFF3A3A3C),
                  onTap: () {
                    _close();
                    widget.onMore();
                  },
                ),
                _SwipeActionButton(
                  width: NotificationSwipeTile.buttonWidth,
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFED4956),
                  onTap: () {
                    _close();
                    widget.onDelete();
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            onTap: isOpen ? _close : widget.onTap,
            child: Transform.translate(
              offset: Offset(_offset, 0),
              child: ColoredBox(
                color: AppColors.surfaceDark,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.width,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
