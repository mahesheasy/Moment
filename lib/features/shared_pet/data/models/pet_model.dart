import 'package:moment/features/shared_pet/domain/entities/pet.dart';

class SharedPetModel {
  SharedPetModel({
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

  factory SharedPetModel.fromJson(Map<String, dynamic> json) {
    return SharedPetModel(
      id: json['id'] as String,
      connectionId: json['connection_id'] as String,
      petType: json['pet_type'] as String,
      petName: json['pet_name'] as String,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      bondScore: json['bond_score'] as int? ?? 0,
      hunger: json['hunger'] as int? ?? 100,
      energy: json['energy'] as int? ?? 100,
      happiness: json['happiness'] as int? ?? 100,
      mood: json['mood'] as String? ?? 'happy',
      stage: json['stage'] as String? ?? 'baby',
      lastStateUpdate: json['last_state_update'] == null
          ? null
          : DateTime.parse(json['last_state_update'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String connectionId;
  final String petType;
  final String petName;
  final int level;
  final int xp;
  final int bondScore;
  final int hunger;
  final int energy;
  final int happiness;
  final String mood;
  final String stage;
  final DateTime? lastStateUpdate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SharedPet toEntity() {
    return SharedPet(
      id: id,
      connectionId: connectionId,
      petType: petTypeFromValue(petType),
      petName: petName,
      level: level,
      xp: xp,
      bondScore: bondScore,
      hunger: hunger,
      energy: energy,
      happiness: happiness,
      mood: petMoodFromValue(mood),
      stage: petStageFromValue(stage),
      lastStateUpdate: lastStateUpdate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class PetActionModel {
  PetActionModel({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.xpEarned,
    required this.createdAt,
  });

  factory PetActionModel.fromJson(Map<String, dynamic> json) {
    return PetActionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actionType: json['action_type'] as String,
      xpEarned: json['xp_earned'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String userId;
  final String actionType;
  final int xpEarned;
  final DateTime createdAt;

  PetActionLog toEntity() {
    return PetActionLog(
      id: id,
      userId: userId,
      actionType: actionType,
      xpEarned: xpEarned,
      createdAt: createdAt,
    );
  }
}
