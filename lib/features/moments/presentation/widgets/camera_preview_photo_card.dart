import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/features/moments/presentation/widgets/camera_moment_preview_widgets.dart';

class CameraPreviewPhotoCard extends StatelessWidget {
  const CameraPreviewPhotoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.xxxlAll,
      child: const Stack(
        fit: StackFit.expand,
        children: [
          MomentPhotoPreview(),
          // Positioned(
          //   top: 10,
          //   left: 10,
          //   child: _PhotoCountBadge(),
          // ),
        ],
      ),
    );
  }
}

class _PhotoCountBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '1/1',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
