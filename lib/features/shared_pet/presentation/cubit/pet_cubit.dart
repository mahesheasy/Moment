import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/shared_pet/domain/entities/pet.dart';
import 'package:moment/features/shared_pet/domain/entities/pet_integration_event.dart';
import 'package:moment/features/shared_pet/domain/repositories/pet_repository.dart';
import 'package:moment/features/shared_pet/domain/services/pet_moment_integration_bus.dart';
import 'package:moment/features/shared_pet/presentation/cubit/pet_state.dart';
import 'package:uuid/uuid.dart';

class PetCubit extends Cubit<PetState> {
  PetCubit(
    this._repository,
    this._integrationBus, {
    required String friendUserId,
  }) : super(PetState(friendUserId: friendUserId));

  final PetRepository _repository;
  final PetMomentIntegrationBus _integrationBus;

  StreamSubscription<SharedPet>? _petSubscription;
  StreamSubscription<PetIntegrationEvent>? _integrationSubscription;
  final _uuid = const Uuid();

  Future<void> load() async {
    emit(state.copyWith(status: PetStatus.loading, clearError: true));
    final bundleResult = await _repository.getPetForFriend(state.friendUserId);
    switch (bundleResult) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: value.pet == null ? PetStatus.loaded : PetStatus.loaded,
            connectionId: value.connectionId,
            pet: value.pet,
          ),
        );
        if (value.pet != null) {
          await _loadActions(value.pet!.id);
          _subscribeRealtime(value.pet!.id);
        }
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: PetStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> createPet({
    required PetType petType,
    required String petName,
  }) async {
    emit(state.copyWith(status: PetStatus.acting, clearError: true));
    final result = await _repository.createPet(
      friendUserId: state.friendUserId,
      petType: petType,
      petName: petName,
    );
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(status: PetStatus.loaded, pet: value),
        );
        _subscribeRealtime(value.id);
        await _loadActions(value.id);
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: PetStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> performAction(PetActionType action) async {
    final pet = state.pet;
    if (pet == null) return;

    emit(state.copyWith(status: PetStatus.acting, clearError: true));

    final idempotencyKey = _uuid.v4();
    final result = await _repository.performAction(
      petId: pet.id,
      action: action,
      idempotencyKey: idempotencyKey,
    );

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(status: PetStatus.loaded, pet: value));
        await _loadActions(value.id);
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: PetStatus.loaded,
            errorMessage: failure.message,
          ),
        );
    }
  }

  void onModelAssetMissing() {
    emit(state.copyWith(modelAssetMissing: true));
  }

  void onModelAssetLoaded() {
    emit(state.copyWith(modelAssetMissing: false));
  }

  void startIntegrationListener() {
    _integrationSubscription ??= _integrationBus.stream.listen((event) {
      if (event.friendUserId != state.friendUserId) return;
      final petId = state.pet?.id ?? event.petId;
      if (petId == null) return;
      unawaited(_applyIntegration(petId, event));
    });
  }

  Future<void> _applyIntegration(
    String petId,
    PetIntegrationEvent event,
  ) async {
    final result = await _repository.applyIntegrationEvent(
      petId: petId,
      event: event,
    );
    if (result case Success(:final value)) {
      emit(state.copyWith(pet: value));
    }
  }

  Future<void> _loadActions(String petId) async {
    final result = await _repository.listActions(petId: petId);
    if (result case Success(:final value)) {
      emit(state.copyWith(actions: value));
    }
  }

  void _subscribeRealtime(String petId) {
    _petSubscription?.cancel();
    _petSubscription = _repository.watchPet(petId).listen(
      (pet) {
        emit(state.copyWith(pet: pet));
      },
      onError: (_) {},
    );
  }

  @override
  Future<void> close() {
    _petSubscription?.cancel();
    _integrationSubscription?.cancel();
    return super.close();
  }
}
