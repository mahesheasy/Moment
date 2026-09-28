import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/errors/postgrest_mapper.dart';
import 'package:moment/features/shared_pet/data/models/pet_model.dart';
import 'package:moment/features/shared_pet/domain/entities/pet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetRemoteDataSource {
  PetRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<({String connectionId, SharedPetModel? pet})> getPetForFriend(
    String friendUserId,
  ) async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'get_shared_pet_for_friend',
      params: {'p_friend_id': friendUserId},
    );
    final petJson = data['pet'];
    return (
      connectionId: data['connection_id'] as String,
      pet: petJson == null
          ? null
          : SharedPetModel.fromJson(Map<String, dynamic>.from(petJson as Map)),
    );
  }

  Future<SharedPetModel> createPet({
    required String friendUserId,
    required PetType petType,
    required String petName,
  }) async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'create_shared_pet',
      params: {
        'p_friend_id': friendUserId,
        'p_pet_type': petTypeToValue(petType),
        'p_pet_name': petName,
      },
    );
    return SharedPetModel.fromJson(data);
  }

  Future<SharedPetModel> performAction({
    required String petId,
    required PetActionType action,
    String? idempotencyKey,
  }) async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'perform_pet_action',
      params: {
        'p_pet_id': petId,
        'p_action_type': petActionTypeToRpc(action),
        'p_idempotency_key': idempotencyKey,
      },
    );
    return SharedPetModel.fromJson(data);
  }

  Future<List<PetActionModel>> listActions({
    required String petId,
    int limit = 30,
  }) async {
    final data = await _client.rpc<List<dynamic>>(
      'list_pet_actions',
      params: {'p_pet_id': petId, 'p_limit': limit},
    );
    return data
        .map(
          (row) => PetActionModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<SharedPetModel> applyIntegrationEvent({
    required String petId,
    required String eventType,
  }) async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'apply_pet_integration_event',
      params: {'p_pet_id': petId, 'p_event_type': eventType},
    );
    return SharedPetModel.fromJson(data);
  }

  Stream<SharedPetModel> watchPet(String petId) {
    return _client
        .from('connection_pets')
        .stream(primaryKey: ['id'])
        .eq('id', petId)
        .map((rows) {
          if (rows.isEmpty) {
            throw StateError('Pet row missing');
          }
          return SharedPetModel.fromJson(Map<String, dynamic>.from(rows.first));
        });
  }

  Failure mapError(Object error) {
    if (error is PostgrestException) {
      return mapPostgrestError(
        error,
        fallback: 'Could not complete pet action.',
      );
    }
    if (error is Failure) return error;
    return UnknownFailure(cause: error);
  }
}
