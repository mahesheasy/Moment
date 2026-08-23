import 'package:flutter/material.dart';

/// Shared accent swatches for app theme and home widget.
const kAccentPresets = <String>[
  '#FF4D7D',
  '#FF6B8A',
  '#C4A1FF',
  '#7EB6FF',
  '#5DDBA0',
  '#FFB86C',
  '#FFE66D',
  '#E8C39E',
];

const kDefaultAccentHex = '#FF6B8A';

Color accentFromHex(String hex) {
  final normalized = hex.replaceFirst('#', '');
  return Color(int.parse('FF$normalized', radix: 16));
}

String accentToHex(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

LinearGradient bloomGradientFor(Color accent) {
  final warm = Color.lerp(accent, const Color(0xFFFF8A5C), 0.45)!;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, warm],
  );
}

Color accentSoftFor(Color accent, {required bool isDark}) {
  if (isDark) return accent.withValues(alpha: 0.2);
  return Color.alphaBlend(accent.withValues(alpha: 0.14), Colors.white);
}
