import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/memories/domain/entities/memory_theme.dart';

void main() {
  test('MemoryThemeStyle provides distinct palettes', () {
    final minimal = MemoryThemeStyle.forTheme(MemoryTheme.minimal);
    final polaroid = MemoryThemeStyle.forTheme(MemoryTheme.polaroid);

    expect(minimal.background, isNot(polaroid.background));
    expect(minimal.titleColor, isNot(polaroid.titleColor));
  });

  test('MemoryTheme labels match premium catalog', () {
    expect(MemoryTheme.values.length, 9);
    expect(MemoryTheme.film.label, 'Film');
  });
}
