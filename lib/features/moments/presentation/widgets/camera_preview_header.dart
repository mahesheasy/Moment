import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';

class CameraPreviewHeader extends StatelessWidget {
  const CameraPreviewHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(AppIcons.back, color: Colors.white, size: 20),
        ),
        Expanded(
          child: Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Your ',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: 'moment',
                      style: TextStyle(color: AppColors.photoPink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share what’s on your mind',
                style: TextStyle(
                  color: AppColors.textTertiaryDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _confirmDelete(context),
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Colors.white.withValues(alpha: 0.85),
            size: 22,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Delete moment?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will discard your photo and go back to the camera.',
          style: TextStyle(color: AppColors.textTertiaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.photoPink),
            ),
          ),
        ],
      ),
    );

    if (discard == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
