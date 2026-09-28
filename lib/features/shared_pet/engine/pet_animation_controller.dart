import 'package:flutter/foundation.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:moment/features/shared_pet/domain/entities/pet_animation_name.dart';

/// Single abstraction over GLB animation clips.
class PetAnimationController {
  PetAnimationController(this._flutter3d);

  final Flutter3DController _flutter3d;

  List<String> _available = [];
  PetAnimationName _current = PetAnimationName.idle;

  ValueListenable<bool> get modelLoaded => _flutter3d.onModelLoaded;

  PetAnimationName get current => _current;

  Future<void> bindAvailableClips() async {
    if (!_flutter3d.onModelLoaded.value) return;
    try {
      _available = await _flutter3d.getAvailableAnimations();
    } on Object {
      _available = [];
    }
  }

  void play(PetAnimationName name, {int loopCount = 0}) {
    _current = name;
    if (!_flutter3d.onModelLoaded.value) return;
    final clip = resolvePetClipName(name, _available);
    if (clip == null) return;
    try {
      _flutter3d.playAnimation(animationName: clip, loopCount: loopCount);
    } on Object {
      // Model still loading
    }
  }

  void playIdle() => play(PetAnimationName.idle, loopCount: 0);
  void playWalk() => play(PetAnimationName.walk, loopCount: 0);
  void playEat() => play(PetAnimationName.eat, loopCount: 1);
  void playDrink() => play(PetAnimationName.drink, loopCount: 1);
  void playSleep() => play(PetAnimationName.sleep, loopCount: 0);
  void playWake() => play(PetAnimationName.wake, loopCount: 1);
  void playPlay() => play(PetAnimationName.play, loopCount: 1);
  void playHappy() => play(PetAnimationName.happy, loopCount: 1);
  void playCelebrate() => play(PetAnimationName.celebrate, loopCount: 1);
  void playSad() => play(PetAnimationName.sad, loopCount: 1);

  void setCameraOrbitForFacing(double facingRadians) {
    if (!_flutter3d.onModelLoaded.value) return;
    final theta = (facingRadians * 180 / 3.14159) + 180;
    try {
      _flutter3d.setCameraOrbit(theta, 75, 2.2);
    } on Object {
      // ignore
    }
  }
}
