import 'package:flutter/material.dart';

/// Room anchor positions in normalized coordinates (x: -1..1, z: -1..1).
class PetRoomAnchor {
  const PetRoomAnchor(this.x, this.z, this.label);

  final double x;
  final double z;
  final String label;

  static const center = PetRoomAnchor(0, 0, 'center');
  static const foodBowl = PetRoomAnchor(-0.55, 0.35, 'food');
  static const waterBowl = PetRoomAnchor(0.55, 0.35, 'water');
  static const bed = PetRoomAnchor(0, -0.55, 'bed');
  static const toy = PetRoomAnchor(0.65, -0.25, 'toy');

  static const randomWalkZones = [
    PetRoomAnchor(-0.25, 0.1, 'zone_a'),
    PetRoomAnchor(0.2, -0.05, 'zone_b'),
    PetRoomAnchor(-0.1, -0.3, 'zone_c'),
    PetRoomAnchor(0.35, 0.15, 'zone_d'),
  ];

  Offset toScreenOffset(Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.58;
    final scale = size.width * 0.32;
    return Offset(cx + x * scale, cy + z * scale * 0.65);
  }
}
