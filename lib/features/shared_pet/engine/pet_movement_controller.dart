import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:moment/features/shared_pet/engine/pet_room_layout.dart';

typedef PetPosition = ({double x, double z});

class PetMovementController {
  PetMovementController({
    this.walkSpeed = 0.45,
  });

  final double walkSpeed;

  final ValueNotifier<PetPosition> position =
      ValueNotifier<PetPosition>((x: 0, z: 0));

  double _facingRadians = 0;
  double get facingRadians => _facingRadians;

  Timer? _timer;
  Completer<void>? _moveCompleter;

  void dispose() {
    _timer?.cancel();
    if (_moveCompleter != null && !_moveCompleter!.isCompleted) {
      _moveCompleter!.complete();
    }
  }

  Future<void> moveTo(PetRoomAnchor anchor) {
    return moveToPoint(anchor.x, anchor.z);
  }

  Future<void> moveToPoint(double destX, double destZ) async {
    _timer?.cancel();
    if (_moveCompleter != null && !_moveCompleter!.isCompleted) {
      _moveCompleter!.complete();
    }
    _moveCompleter = Completer<void>();

    final startX = position.value.x;
    final startZ = position.value.z;
    final dx = destX - startX;
    final dz = destZ - startZ;
    final distance = math.sqrt(dx * dx + dz * dz);

    if (distance < 0.02) {
      _moveCompleter!.complete();
      return _moveCompleter!.future;
    }

    _facingRadians = math.atan2(dx, -dz);
    final durationMs = (distance / walkSpeed * 1000).clamp(400, 4000).round();
    final started = DateTime.now();

    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      final t = (elapsed / durationMs).clamp(0.0, 1.0);
      final eased = Curves.easeInOut.transform(t);
      position.value = (
        x: startX + dx * eased,
        z: startZ + dz * eased,
      );
      if (t >= 1.0) {
        timer.cancel();
        position.value = (x: destX, z: destZ);
        if (!_moveCompleter!.isCompleted) _moveCompleter!.complete();
      }
    });

    return _moveCompleter!.future;
  }

  void snapTo(PetRoomAnchor anchor) {
    position.value = (x: anchor.x, z: anchor.z);
  }
}
