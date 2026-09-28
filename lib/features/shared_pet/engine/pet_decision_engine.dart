import 'dart:math';

import 'package:moment/features/shared_pet/domain/entities/pet.dart';
import 'package:moment/features/shared_pet/engine/pet_room_layout.dart';

enum PetAutonomousIntent {
  idleWander,
  goEat,
  goDrink,
  goSleep,
  goPlay,
}

class PetDecisionEngine {
  PetDecisionEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  PetAutonomousIntent decide(SharedPet pet) {
    if (pet.mood == PetMood.sleeping) {
      return PetAutonomousIntent.idleWander;
    }
    if (pet.hunger < 35) return PetAutonomousIntent.goEat;
    if (pet.energy < 25) return PetAutonomousIntent.goSleep;
    if (pet.happiness < 35) return PetAutonomousIntent.goPlay;
    if (pet.hunger < 55 && _random.nextDouble() < 0.25) {
      return PetAutonomousIntent.goDrink;
    }
    if (_random.nextDouble() < 0.35) {
      return PetAutonomousIntent.idleWander;
    }
    return PetAutonomousIntent.idleWander;
  }

  PetRoomAnchor anchorFor(PetAutonomousIntent intent) {
    return switch (intent) {
      PetAutonomousIntent.goEat => PetRoomAnchor.foodBowl,
      PetAutonomousIntent.goDrink => PetRoomAnchor.waterBowl,
      PetAutonomousIntent.goSleep => PetRoomAnchor.bed,
      PetAutonomousIntent.goPlay => PetRoomAnchor.toy,
      PetAutonomousIntent.idleWander =>
        PetRoomAnchor.randomWalkZones[_random.nextInt(
          PetRoomAnchor.randomWalkZones.length,
        )],
    };
  }
}
