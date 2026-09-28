import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/shared_pet/engine/pet_movement_controller.dart';
import 'package:moment/features/shared_pet/engine/pet_room_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('moveTo updates position without teleport at start', () async {
    final movement = PetMovementController(walkSpeed: 2);
    expect(movement.position.value.x, 0);
    expect(movement.position.value.z, 0);

    await movement.moveTo(PetRoomAnchor.foodBowl);
    expect(movement.position.value.x, closeTo(PetRoomAnchor.foodBowl.x, 0.02));
    expect(movement.position.value.z, closeTo(PetRoomAnchor.foodBowl.z, 0.02));
    movement.dispose();
  });
}
