import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';

class MomentSpaceComposer extends StatefulWidget {
  const MomentSpaceComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onPlus,
    required this.onPickImage,
    required this.onSparkle,
    this.onTextChanged,
    this.focusNode,
    this.isEditing = false,
    super.key,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onPlus;
  final VoidCallback onPickImage;
  final VoidCallback onSparkle;
  final ValueChanged<String>? onTextChanged;
  final FocusNode? focusNode;
  final bool isEditing;

  @override
  State<MomentSpaceComposer> createState() => _MomentSpaceComposerState();
}

class _MomentSpaceComposerState extends State<MomentSpaceComposer> {
  var _hasText = false;
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final next = text.trim().isNotEmpty;
    if (next != _hasText) setState(() => _hasText = next);
    widget.onTextChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canSend = _hasText && !widget.isSending;
    final accent = MomentSpaceTheme.composerAccent(context);

    return Container(
      color: MomentSpaceTheme.composerBarBackground(context),
      padding: EdgeInsets.fromLTRB(14, 12, 14, 12 + bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!widget.isEditing) ...[
            _PlusButton(onTap: widget.onPlus),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: MomentSpaceTheme.composerPillFill(context),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: MomentSpaceTheme.composerPillBorder(context),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: MomentSpaceTheme.composerText(context),
                        height: 1.3,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.isEditing
                            ? 'Edit message...'
                            : 'Share a moment...',
                        hintStyle: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: MomentSpaceTheme.composerHint(context),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.fromLTRB(18, 14, 8, 14),
                      ),
                      onSubmitted: canSend ? (_) => widget.onSend() : null,
                    ),
                  ),
                  if (!widget.isEditing) ...[
                    _ComposerIconButton(
                      onTap: widget.onPickImage,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          MomentSpaceTheme.composerIconMuted(context),
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          'assets/images/home_gallery_icon.png',
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    _ComposerIconButton(
                      onTap: widget.onSparkle,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 21,
                        color: accent,
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: GestureDetector(
                      onTap: canSend ? widget.onSend : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: canSend
                              ? accent
                              : accent.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: widget.isSending
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                widget.isEditing
                                    ? Icons.check_rounded
                                    : Icons.send_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: MomentSpaceTheme.composerPlusFill(context),
          shape: BoxShape.circle,
          border: Border.all(
            color: MomentSpaceTheme.composerPillBorder(context),
          ),
        ),
        child: Icon(
          Icons.add_rounded,
          size: 24,
          color: mc.textPrimary.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 52,
        child: Center(child: child),
      ),
    );
  }
}
