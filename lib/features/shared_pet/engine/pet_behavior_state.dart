enum PetBehaviorState {
  idle,
  walking,
  eating,
  drinking,
  playing,
  sleeping,
  waking,
  celebrating,
  reacting,
}

extension PetBehaviorStateTransitions on PetBehaviorState {
  bool canTransitionTo(PetBehaviorState next) {
    if (this == next) return true;
    return switch (this) {
      PetBehaviorState.idle => next == PetBehaviorState.walking ||
          next == PetBehaviorState.reacting ||
          next == PetBehaviorState.celebrating,
      PetBehaviorState.walking => next == PetBehaviorState.eating ||
          next == PetBehaviorState.drinking ||
          next == PetBehaviorState.playing ||
          next == PetBehaviorState.sleeping ||
          next == PetBehaviorState.idle ||
          next == PetBehaviorState.reacting,
      PetBehaviorState.eating => next == PetBehaviorState.idle,
      PetBehaviorState.drinking => next == PetBehaviorState.idle,
      PetBehaviorState.playing => next == PetBehaviorState.idle ||
          next == PetBehaviorState.celebrating,
      PetBehaviorState.sleeping => next == PetBehaviorState.waking,
      PetBehaviorState.waking => next == PetBehaviorState.idle,
      PetBehaviorState.celebrating => next == PetBehaviorState.idle,
      PetBehaviorState.reacting => next == PetBehaviorState.idle,
    };
  }
}
