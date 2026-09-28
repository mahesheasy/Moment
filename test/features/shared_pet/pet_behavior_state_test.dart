import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/shared_pet/engine/pet_behavior_state.dart';

void main() {
  test('idle can transition to walking', () {
    expect(
      PetBehaviorState.idle.canTransitionTo(PetBehaviorState.walking),
      isTrue,
    );
  });

  test('sleeping cannot transition to eating without wake', () {
    expect(
      PetBehaviorState.sleeping.canTransitionTo(PetBehaviorState.eating),
      isFalse,
    );
    expect(
      PetBehaviorState.sleeping.canTransitionTo(PetBehaviorState.waking),
      isTrue,
    );
  });

  test('eating returns to idle', () {
    expect(
      PetBehaviorState.eating.canTransitionTo(PetBehaviorState.idle),
      isTrue,
    );
  });
}
