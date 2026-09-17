import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/features/chat/presentation/theme/moment_space_theme.dart';

Future<String?> showChatEmojiPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MomentSpaceTheme.surfaceElevated(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final height = MediaQuery.sizeOf(context).height * 0.48;

      return SafeArea(
        child: SizedBox(
          height: height,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              Navigator.pop(context, emoji.emoji);
            },
            config: Config(
              height: height,
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                backgroundColor: MomentSpaceTheme.surfaceElevated(context),
                columns: 8,
                emojiSizeMax: 28,
                buttonMode: ButtonMode.MATERIAL,
              ),
              categoryViewConfig: CategoryViewConfig(
                backgroundColor: MomentSpaceTheme.surfaceElevated(context),
                indicatorColor: AppColors.accent,
                iconColorSelected: AppColors.accent,
                iconColor: AppColors.textTertiaryDark,
              ),
              bottomActionBarConfig: const BottomActionBarConfig(
                enabled: false,
              ),
              searchViewConfig: SearchViewConfig(
                backgroundColor: MomentSpaceTheme.surfaceElevated(context),
                hintText: 'Search emoji',
              ),
            ),
          ),
        ),
      );
    },
  );
}
