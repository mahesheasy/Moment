import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/features/shared_pet/domain/entities/pet.dart';
import 'package:moment/features/shared_pet/engine/pet_animation_controller.dart';
import 'package:moment/features/shared_pet/engine/pet_movement_controller.dart';

class Pet3DView extends StatefulWidget {
  const Pet3DView({
    required this.pet,
    required this.movement,
    required this.flutter3dController,
    required this.animationController,
    required this.onAssetMissing,
    required this.onAssetLoaded,
    super.key,
  });

  final SharedPet pet;
  final PetMovementController movement;
  final Flutter3DController flutter3dController;
  final PetAnimationController animationController;
  final VoidCallback onAssetMissing;
  final VoidCallback onAssetLoaded;

  @override
  State<Pet3DView> createState() => _Pet3DViewState();
}

class _Pet3DViewState extends State<Pet3DView> {
  bool _assetExists = true;
  bool _checkedAsset = false;

  @override
  void initState() {
    super.initState();
    _checkAsset();
    widget.flutter3dController.onModelLoaded.addListener(_onModelLoaded);
  }

  Future<void> _checkAsset() async {
    try {
      await rootBundle.load(widget.pet.assetPath);
      if (mounted) {
        setState(() {
          _assetExists = true;
          _checkedAsset = true;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _assetExists = false;
          _checkedAsset = true;
        });
        widget.onAssetMissing();
      }
    }
  }

  void _onModelLoaded() {
    if (widget.flutter3dController.onModelLoaded.value) {
      widget.onAssetLoaded();
      widget.animationController.bindAvailableClips().then((_) {
        widget.animationController.playIdle();
      });
    }
  }

  @override
  void dispose() {
    widget.flutter3dController.onModelLoaded.removeListener(_onModelLoaded);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedAsset) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_assetExists) {
      return _MissingAssetPlaceholder(petName: widget.pet.petName);
    }

    return ValueListenableBuilder(
      valueListenable: widget.movement.position,
      builder: (context, pos, _) {
        final size = MediaQuery.sizeOf(context);
        final cx = size.width * 0.5;
        final cy = size.height * 0.58;
        final scale = size.width * 0.32;
        final left = cx + pos.x * scale - size.width * 0.28;
        final top = cy + pos.z * scale * 0.65 - size.width * 0.28;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: left,
              top: top,
              width: size.width * 0.56,
              height: size.width * 0.56,
              child: Transform.rotate(
                angle: widget.movement.facingRadians,
                child: Flutter3DViewer(
                  controller: widget.flutter3dController,
                  src: widget.pet.assetPath,
                  enableTouch: false,
                  activeGestureInterceptor: true,
                  progressBarColor: AppColors.accent.withValues(alpha: 0.6),
                  onError: (_) => widget.onAssetMissing(),
                  onLoad: (_) => _onModelLoaded(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MissingAssetPlaceholder extends StatelessWidget {
  const _MissingAssetPlaceholder({required this.petName});

  final String petName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 64, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              '3D model not installed',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add assets/pets/cat/cat.glb with animation clips '
              '(Idle, Walk, Eat, Drink, Sleep, Wake, Play, Happy, Celebrate). '
              '$petName will appear here once the GLB is bundled.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
