import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/shared_pet/data/datasources/pet_remote_datasource.dart';
import 'package:moment/features/shared_pet/domain/entities/pet.dart';
import 'package:moment/features/shared_pet/domain/entities/pet_integration_event.dart';
import 'package:moment/features/shared_pet/domain/repositories/pet_repository.dart';

class PetRepositoryImpl implements PetRepository {
  PetRepositoryImpl(this._remote, this._userIdProvider);

  final PetRemoteDataSource _remote;
  final String? Function() _userIdProvider;

  @override
  Future<Result<SharedPetBundle>> getPetForFriend(String friendUserId) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());
    try {
      final result = await _remote.getPetForFriend(friendUserId);
      return Success(
        SharedPetBundle(
          connectionId: result.connectionId,
          pet: result.pet?.toEntity(),
        ),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<SharedPet>> createPet({
    required String friendUserId,
    required PetType petType,
    required String petName,
  }) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());
    try {
      final model = await _remote.createPet(
        friendUserId: friendUserId,
        petType: petType,
        petName: petName,
      );
      return Success(model.toEntity());
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<SharedPet>> performAction({
    required String petId,
    required PetActionType action,
    String? idempotencyKey,
  }) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());
    try {
      final model = await _remote.performAction(
        petId: petId,
        action: action,
        idempotencyKey: idempotencyKey,
      );
      return Success(model.toEntity());
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<PetActionLog>>> listActions({
    required String petId,
    int limit = 30,
  }) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());
    try {
      final models = await _remote.listActions(petId: petId, limit: limit);
      return Success(models.map((m) => m.toEntity()).toList());
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<SharedPet>> applyIntegrationEvent({
    required String petId,
    required PetIntegrationEvent event,
  }) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());
    try {
      final model = await _remote.applyIntegrationEvent(
        petId: petId,
        eventType: event.rpcEventType,
      );
      return Success(model.toEntity());
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Stream<SharedPet> watchPet(String petId) {
    return _remote.watchPet(petId).map((m) => m.toEntity());
  }
}
