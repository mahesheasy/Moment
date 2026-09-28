/// Hooks for existing Moment features to notify the shared pet module.
enum PetIntegrationEventType {
  momentShared,
  reactionReceived,
  activityCompleted,
  specialDay,
}

class PetIntegrationEvent {
  const PetIntegrationEvent({
    required this.type,
    required this.friendUserId,
    this.petId,
  });

  final PetIntegrationEventType type;
  final String friendUserId;
  final String? petId;

  String get rpcEventType => switch (type) {
        PetIntegrationEventType.momentShared => 'moment_shared',
        PetIntegrationEventType.reactionReceived => 'reaction_received',
        PetIntegrationEventType.activityCompleted => 'activity_completed',
        PetIntegrationEventType.specialDay => 'activity_completed',
      };
}
