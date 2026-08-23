import 'package:flutter/material.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';

class CircleStyle {
  const CircleStyle._();

  static Color accent(CircleType type) {
    return switch (type) {
      CircleType.us => const Color(0xFFFF6B8A),
      CircleType.squad => const Color(0xFFC4A1FF),
      CircleType.family => const Color(0xFF5DDBA0),
      CircleType.college => const Color(0xFF7EB6FF),
      CircleType.custom => const Color(0xFFE8C39E),
    };
  }

  static Color cardBackground(CircleType type) {
    return switch (type) {
      CircleType.us => const Color(0xFF2A1620),
      CircleType.squad => const Color(0xFF1E1730),
      CircleType.family => const Color(0xFF14261E),
      CircleType.college => const Color(0xFF151E2E),
      CircleType.custom => const Color(0xFF241C16),
    };
  }

  static Color iconWell(CircleType type) {
    return switch (type) {
      CircleType.us => const Color(0xFFFF8A5C),
      CircleType.squad => const Color(0xFFD4C0FF),
      CircleType.family => const Color(0xFF8AE4B4),
      CircleType.college => const Color(0xFF9CC8FF),
      CircleType.custom => const Color(0xFFF0D4B0),
    };
  }
}
