import 'package:moment/core/result/result.dart';
import 'package:moment/features/shared_pet/domain/entities/pet.dart';
import 'package:moment/features/shared_pet/domain/entities/pet_integration_event.dart';

class SharedPetBundle {
  const SharedPetBundle({
    required this.connectionId,
    this.pet,
  });

  final String connectionId;
  final SharedPet? pet;
}

abstract class PetRepository {
  Future<Result<SharedPetBundle>> getPetForFriend(String friendUserId);

  Future<Result<SharedPet>> createPet({
    required String friendUserId,
    required PetType petType,
    required String petName,
  });

  Future<Result<SharedPet>> performAction({
    required String petId,
    required PetActionType action,
    String? idempotencyKey,
  });

  Future<Result<List<PetActionLog>>> listActions({
    required String petId,
    int limit = 30,
  });

  Future<Result<SharedPet>> applyIntegrationEvent({
    required String petId,
    required PetIntegrationEvent event,
  });

  Stream<SharedPet> watchPet(String petId);
}
