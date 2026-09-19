import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';

class CameraPreviewCaptionField extends StatelessWidget {
  const CameraPreviewCaptionField({
    required this.controller,
    required this.maxLength,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final int maxLength;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: 3,
            minLines: 1,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                const SizedBox.shrink(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.35,
            ),
            cursorColor: AppColors.violet,
            decoration: InputDecoration(
              hintText: 'Add a caption...',
              hintStyle: TextStyle(
                color: AppColors.textTertiaryDark,
                fontSize: 15,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.only(right: 48, bottom: 14),
            ),
            onChanged: onChanged,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                return Text(
                  '${value.text.length}/$maxLength',
                  style: TextStyle(
                    color: AppColors.textTertiaryDark,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
