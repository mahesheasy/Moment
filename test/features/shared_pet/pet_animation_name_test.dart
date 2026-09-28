import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/shared_pet/domain/entities/pet_animation_name.dart';

void main() {
  test('resolves walk clip with case insensitivity', () {
    final clip = resolvePetClipName(
      PetAnimationName.walk,
      ['idle', 'Walk', 'Eat'],
    );
    expect(clip, 'Walk');
  });

  test('falls back to idle when clip missing', () {
    final clip = resolvePetClipName(
      PetAnimationName.play,
      ['Idle'],
    );
    expect(clip, 'Idle');
  });
}
