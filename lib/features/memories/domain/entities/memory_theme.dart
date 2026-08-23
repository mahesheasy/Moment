import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum MemoryType {
  prompt,
  circle,
  anniversary,
  birthday,
  trip,
  custom;

  String get label => switch (this) {
    MemoryType.prompt => 'Prompt',
    MemoryType.circle => 'Circle',
    MemoryType.anniversary => 'Anniversary',
    MemoryType.birthday => 'Birthday',
    MemoryType.trip => 'Trip',
    MemoryType.custom => 'Custom',
  };

  static MemoryType fromValue(String value) {
    return MemoryType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MemoryType.custom,
    );
  }
}

enum MemoryTheme {
  minimal,
  glass,
  film,
  polaroid,
  midnight,
  sunset,
  love,
  retro,
  memory;

  String get label => switch (this) {
    MemoryTheme.minimal => 'Minimal',
    MemoryTheme.glass => 'Glass',
    MemoryTheme.film => 'Film',
    MemoryTheme.polaroid => 'Polaroid',
    MemoryTheme.midnight => 'Midnight',
    MemoryTheme.sunset => 'Sunset',
    MemoryTheme.love => 'Love',
    MemoryTheme.retro => 'Retro',
    MemoryTheme.memory => 'Memory',
  };

  static MemoryTheme fromValue(String value) {
    return MemoryTheme.values.firstWhere(
      (theme) => theme.name == value,
      orElse: () => MemoryTheme.minimal,
    );
  }
}

class MemoryThemeStyle {
  const MemoryThemeStyle({
    required this.background,
    required this.surface,
    required this.titleColor,
    required this.bodyColor,
    required this.borderRadius,
  });

  final Color background;
  final Color surface;
  final Color titleColor;
  final Color bodyColor;
  final double borderRadius;

  static MemoryThemeStyle forTheme(MemoryTheme theme) {
    return switch (theme) {
      MemoryTheme.glass => const MemoryThemeStyle(
        background: Color(0xFF1A1A1A),
        surface: Color(0x33FFFFFF),
        titleColor: Color(0xFFFFFFFF),
        bodyColor: Color(0xB3FFFFFF),
        borderRadius: 16,
      ),
      MemoryTheme.film => const MemoryThemeStyle(
        background: Color(0xFF0D0D0D),
        surface: Color(0xFF171717),
        titleColor: Color(0xFFF5F5F5),
        bodyColor: Color(0xFFAAAAAA),
        borderRadius: 8,
      ),
      MemoryTheme.polaroid => const MemoryThemeStyle(
        background: Color(0xFFF7F4EF),
        surface: Color(0xFFFFFFFF),
        titleColor: Color(0xFF2D2A26),
        bodyColor: Color(0xFF6B6560),
        borderRadius: 4,
      ),
      MemoryTheme.midnight => const MemoryThemeStyle(
        background: Color(0xFF0B132B),
        surface: Color(0xFF1C2541),
        titleColor: Color(0xFFE0E7FF),
        bodyColor: Color(0xFF9CA8D9),
        borderRadius: 16,
      ),
      MemoryTheme.sunset => const MemoryThemeStyle(
        background: Color(0xFF3D1F1F),
        surface: Color(0xFF5C2E2E),
        titleColor: Color(0xFFFFE8D6),
        bodyColor: Color(0xFFE8B4A0),
        borderRadius: 16,
      ),
      MemoryTheme.love => const MemoryThemeStyle(
        background: Color(0xFF3A1F2B),
        surface: Color(0xFF4E2A3C),
        titleColor: Color(0xFFFFE4EC),
        bodyColor: Color(0xFFE8AFC4),
        borderRadius: 20,
      ),
      MemoryTheme.retro => const MemoryThemeStyle(
        background: Color(0xFF2A2118),
        surface: Color(0xFF3D3228),
        titleColor: Color(0xFFF5DEB3),
        bodyColor: Color(0xFFC9B08A),
        borderRadius: 12,
      ),
      MemoryTheme.memory => const MemoryThemeStyle(
        background: Color(0xFFEDE6DA),
        surface: Color(0xFFF7F2EA),
        titleColor: Color(0xFF4A4036),
        bodyColor: Color(0xFF7A7066),
        borderRadius: 16,
      ),
      MemoryTheme.minimal => const MemoryThemeStyle(
        background: Color(0xFF111111),
        surface: Color(0xFF1C1C1C),
        titleColor: Color(0xFFFFFFFF),
        bodyColor: Color(0xFFAAAAAA),
        borderRadius: 16,
      ),
    };
  }
}

class MemoryThemeCatalog extends Equatable {
  const MemoryThemeCatalog({
    required this.themes,
    required this.memoryTypes,
    required this.isPremium,
  });

  final List<MemoryTheme> themes;
  final List<MemoryType> memoryTypes;
  final bool isPremium;

  @override
  List<Object?> get props => [themes, memoryTypes, isPremium];
}
