/// Logical animation names mapped to GLB clip names at runtime.
enum PetAnimationName {
  idle,
  walk,
  run,
  eat,
  drink,
  sleep,
  wake,
  play,
  happy,
  sad,
  celebrate,
}

extension PetAnimationNameX on PetAnimationName {
  /// Preferred clip names to try in the GLB (first match wins).
  List<String> get clipCandidates => switch (this) {
        PetAnimationName.idle => ['Idle', 'idle', 'IDLE', 'Survey'],
        PetAnimationName.walk => ['Walk', 'walk', 'WALK'],
        PetAnimationName.run => ['Run', 'run', 'RUN'],
        PetAnimationName.eat => ['Eat', 'eat', 'EAT', 'Walk'],
        PetAnimationName.drink => ['Drink', 'drink', 'DRINK', 'Walk'],
        PetAnimationName.sleep => ['Sleep', 'sleep', 'SLEEP', 'Survey'],
        PetAnimationName.wake => ['Wake', 'wake', 'WAKE', 'Run'],
        PetAnimationName.play => ['Play', 'play', 'PLAY', 'Run'],
        PetAnimationName.happy => ['Happy', 'happy', 'HAPPY', 'Run'],
        PetAnimationName.sad => ['Sad', 'sad', 'SAD', 'Survey'],
        PetAnimationName.celebrate => ['Celebrate', 'celebrate', 'CELEBRATE', 'Run'],
      };
}

String? resolvePetClipName(
  PetAnimationName logical,
  List<String> availableClips,
) {
  final lower = availableClips.map((c) => c.toLowerCase()).toList();
  for (final candidate in logical.clipCandidates) {
    final idx = lower.indexOf(candidate.toLowerCase());
    if (idx >= 0) return availableClips[idx];
  }
  if (logical != PetAnimationName.idle) {
    return resolvePetClipName(PetAnimationName.idle, availableClips);
  }
  return availableClips.isNotEmpty ? availableClips.first : null;
}
