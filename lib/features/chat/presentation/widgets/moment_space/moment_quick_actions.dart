import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';

enum MomentQuickAction { photo, video, music, text }

class MomentQuickActions extends StatelessWidget {
  const MomentQuickActions({required this.onAction, super.key});

  final ValueChanged<MomentQuickAction> onAction;

  static const _actions = [
    (
      MomentQuickAction.photo,
      Icons.photo_camera_outlined,
      'Share Photo',
      'Capture a moment',
    ),
    (
      MomentQuickAction.video,
      Icons.videocam_outlined,
      'Share Video',
      'Relive the moment',
    ),
    (
      MomentQuickAction.music,
      Icons.music_note_outlined,
      'Share Music',
      'Your vibe, your song',
    ),
    (
      MomentQuickAction.text,
      Icons.edit_outlined,
      'Share Text',
      'Just your thoughts',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        itemCount: _actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (action, icon, title, subtitle) = _actions[index];
          return GestureDetector(
            onTap: () => onAction(action),
            child: Container(
              width: 118,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: MomentSpaceTheme.cardDecoration(
                context,
                radius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: context.mc.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, size: 13, color: context.mc.accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: MomentSpaceTheme.textPrimary(context),
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 8,
                            color: MomentSpaceTheme.textTertiary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
