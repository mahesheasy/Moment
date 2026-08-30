import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/features/chat/presentation/models/moment_timeline_models.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';

class MomentSpaceTabs extends StatelessWidget {
  const MomentSpaceTabs({
    required this.active,
    required this.onChanged,
    super.key,
  });

  final MomentSpaceTab active;
  final ValueChanged<MomentSpaceTab> onChanged;

  static const _tabs = [
    (MomentSpaceTab.moments, 'Moments', Icons.auto_awesome_rounded),
    (MomentSpaceTab.media, 'Media', Icons.image_outlined),
    (MomentSpaceTab.shared, 'Shared', Icons.link_rounded),
    (MomentSpaceTab.about, 'About', Icons.info_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        itemCount: _tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final (tab, label, icon) = _tabs[index];
          final isActive = tab == active;
          return GestureDetector(
            onTap: () => onChanged(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: MomentSpaceTheme.pillDecoration(
                context,
                active: isActive,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 12,
                    color: isActive
                        ? Colors.white
                        : MomentSpaceTheme.textTertiary(context),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : MomentSpaceTheme.textSecondary(context),
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
