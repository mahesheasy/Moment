import 'package:equatable/equatable.dart';

enum PetType { cat, dog, bunny }

enum PetMood { happy, hungry, tired, sad, excited, sleeping }

enum PetStage { baby, young, adult, special }

enum PetActionType {
  create,
  feed,
  play,
  pet,
  drink,
  sleep,
  wake,
  momentEvent,
}

class SharedPet extends Equatable {
  const SharedPet({
    required this.id,
    required this.connectionId,
    required this.petType,
    required this.petName,
    required this.level,
    required this.xp,
    required this.bondScore,
    required this.hunger,
    required this.energy,
    required this.happiness,
    required this.mood,
    required this.stage,
    this.lastStateUpdate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String connectionId;
  final PetType petType;
  final String petName;
  final int level;
  final int xp;
  final int bondScore;
  final int hunger;
  final int energy;
  final int happiness;
  final PetMood mood;
  final PetStage stage;
  final DateTime? lastStateUpdate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const int xpPerLevel = 100;

  int get xpProgressInLevel => xp;
  double get xpProgressFraction => xp / xpPerLevel;

  String get assetPath => switch (petType) {
        PetType.cat => 'assets/pets/cat/cat.glb',
        PetType.dog => 'assets/pets/dog/dog.glb',
        PetType.bunny => 'assets/pets/bunny/bunny.glb',
      };

  @override
  List<Object?> get props => [
        id,
        connectionId,
        petType,
        petName,
        level,
        xp,
        bondScore,
        hunger,
        energy,
        happiness,
        mood,
        stage,
        lastStateUpdate,
        createdAt,
        updatedAt,
      ];
}

class PetActionLog extends Equatable {
  const PetActionLog({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.xpEarned,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String actionType;
  final int xpEarned;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userId, actionType, xpEarned, createdAt];
}

PetType petTypeFromValue(String value) {
  return switch (value) {
    'dog' => PetType.dog,
    'bunny' => PetType.bunny,
    _ => PetType.cat,
  };
}

PetMood petMoodFromValue(String value) {
  return switch (value) {
    'hungry' => PetMood.hungry,
    'tired' => PetMood.tired,
    'sad' => PetMood.sad,
    'excited' => PetMood.excited,
    'sleeping' => PetMood.sleeping,
    _ => PetMood.happy,
  };
}

PetStage petStageFromValue(String value) {
  return switch (value) {
    'young' => PetStage.young,
    'adult' => PetStage.adult,
    'special' => PetStage.special,
    _ => PetStage.baby,
  };
}

String petTypeToValue(PetType type) => type.name;

String petActionTypeToRpc(PetActionType type) => switch (type) {
      PetActionType.feed => 'feed',
      PetActionType.play => 'play',
      PetActionType.pet => 'pet',
      PetActionType.drink => 'drink',
      PetActionType.sleep => 'sleep',
      PetActionType.wake => 'wake',
      PetActionType.create => 'create',
      PetActionType.momentEvent => 'moment_event',
    };
