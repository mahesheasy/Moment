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
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canSend = _hasText && !widget.isSending;

    return Container(
      color: MomentSpaceTheme.composerBarBackground,
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _CircleIconButton(
            icon: Icons.add_rounded,
            onTap: widget.onPlus,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: MomentSpaceTheme.composerPillBackground,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: MomentSpaceTheme.textPrimary(context),
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share a moment...',
                        hintStyle: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: MomentSpaceTheme.textTertiary(context),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.fromLTRB(
                          18,
                          12,
                          4,
                          12,
                        ),
                      ),
                      onSubmitted: canSend ? (_) => widget.onSend() : null,
                    ),
                  ),
                  _PillIconButton(
                    icon: Icons.image_outlined,
                    onTap: widget.onPickImage,
                  ),
                  _PillIconButton(
                    icon: Icons.auto_awesome_outlined,
                    onTap: widget.onSparkle,
                    accent: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 6, 6, 6),
                    child: GestureDetector(
                      onTap: canSend ? widget.onSend : null,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: MomentSpaceTheme.accentGradient(context),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.mc.accent.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: widget.isSending
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                size: 17,
                                color: canSend
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.55),
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: MomentSpaceTheme.composerPillBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: MomentSpaceTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }
}

class _PillIconButton extends StatelessWidget {
  const _PillIconButton({
    required this.icon,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: onTap,
      icon: Icon(
        icon,
        size: accent ? 20 : 21,
        color: accent
            ? context.mc.accent
            : MomentSpaceTheme.textTertiary(context),
      ),
    );
  }
}
