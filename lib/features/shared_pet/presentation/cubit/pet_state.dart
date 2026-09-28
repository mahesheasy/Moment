import 'package:equatable/equatable.dart';
import 'package:moment/features/shared_pet/domain/entities/pet.dart';

enum PetStatus { initial, loading, loaded, acting, failure, missingAsset }

class PetState extends Equatable {
  const PetState({
    this.status = PetStatus.initial,
    this.friendUserId = '',
    this.connectionId,
    this.pet,
    this.actions = const [],
    this.errorMessage,
    this.modelAssetMissing = false,
    this.pendingUserAction,
  });

  final PetStatus status;
  final String friendUserId;
  final String? connectionId;
  final SharedPet? pet;
  final List<PetActionLog> actions;
  final String? errorMessage;
  final bool modelAssetMissing;
  final PetActionType? pendingUserAction;

  PetState copyWith({
    PetStatus? status,
    String? friendUserId,
    String? connectionId,
    SharedPet? pet,
    List<PetActionLog>? actions,
    String? errorMessage,
    bool? modelAssetMissing,
    PetActionType? pendingUserAction,
    bool clearPendingAction = false,
    bool clearError = false,
  }) {
    return PetState(
      status: status ?? this.status,
      friendUserId: friendUserId ?? this.friendUserId,
      connectionId: connectionId ?? this.connectionId,
      pet: pet ?? this.pet,
      actions: actions ?? this.actions,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      modelAssetMissing: modelAssetMissing ?? this.modelAssetMissing,
      pendingUserAction: clearPendingAction
          ? null
          : pendingUserAction ?? this.pendingUserAction,
    );
  }

  @override
  List<Object?> get props => [
        status,
        friendUserId,
        connectionId,
        pet,
        actions,
        errorMessage,
        modelAssetMissing,
        pendingUserAction,
      ];
}
