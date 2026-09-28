import 'dart:async';

import 'package:moment/features/shared_pet/domain/entities/pet_integration_event.dart';

/// Publish-only bus; consumers subscribe via [PetMomentIntegrationBus.stream].
class PetMomentIntegrationBus {
  PetMomentIntegrationBus();

  final _controller = StreamController<PetIntegrationEvent>.broadcast();

  Stream<PetIntegrationEvent> get stream => _controller.stream;

  void publish(PetIntegrationEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}
