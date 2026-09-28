import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/shared_pet/domain/entities/pet.dart';
import 'package:moment/features/shared_pet/domain/repositories/pet_repository.dart';
import 'package:moment/features/shared_pet/domain/services/pet_moment_integration_bus.dart';
import 'package:moment/features/shared_pet/presentation/cubit/pet_cubit.dart';
import 'package:moment/features/shared_pet/presentation/cubit/pet_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockPetRepository extends Mock implements PetRepository {}

void main() {
  late _MockPetRepository repository;
  late PetMomentIntegrationBus bus;

  const pet = SharedPet(
    id: 'pet-1',
    connectionId: 'conn-1',
    petType: PetType.cat,
    petName: 'Milo',
    level: 1,
    xp: 0,
    bondScore: 0,
    hunger: 80,
    energy: 80,
    happiness: 80,
    mood: PetMood.happy,
    stage: PetStage.baby,
  );

  setUpAll(() {
    registerFallbackValue(PetActionType.feed);
  });

  setUp(() {
    repository = _MockPetRepository();
    bus = PetMomentIntegrationBus();
  });

  blocTest<PetCubit, PetState>(
    'load sets pet when bundle has pet',
    build: () {
      when(() => repository.getPetForFriend('friend-1')).thenAnswer(
        (_) async => Success(
          SharedPetBundle(connectionId: 'conn-1', pet: pet),
        ),
      );
      when(() => repository.listActions(petId: any(named: 'petId')))
          .thenAnswer((_) async => const Success([]));
      when(() => repository.watchPet(any())).thenAnswer(
        (_) => const Stream.empty(),
      );
      return PetCubit(repository, bus, friendUserId: 'friend-1');
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<PetState>().having((s) => s.status, 'status', PetStatus.loading),
      isA<PetState>()
          .having((s) => s.pet?.petName, 'name', 'Milo')
          .having((s) => s.status, 'status', PetStatus.loaded),
    ],
  );

  blocTest<PetCubit, PetState>(
    'performAction surfaces failure message',
    build: () {
      when(() => repository.getPetForFriend('friend-1')).thenAnswer(
        (_) async => Success(
          SharedPetBundle(connectionId: 'conn-1', pet: pet),
        ),
      );
      when(() => repository.listActions(petId: any(named: 'petId')))
          .thenAnswer((_) async => const Success([]));
      when(() => repository.watchPet(any())).thenAnswer(
        (_) => const Stream.empty(),
      );
      when(
        () => repository.performAction(
          petId: any(named: 'petId'),
          action: any(named: 'action'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => const Failed(ValidationFailure(message: 'cooldown')));
      return PetCubit(repository, bus, friendUserId: 'friend-1');
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.performAction(PetActionType.feed);
    },
    verify: (_) {},
  );
}
