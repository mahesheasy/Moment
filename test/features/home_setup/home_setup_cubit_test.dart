import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moment/app/lifecycle/session_cubit.dart';
import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/home_setup/domain/entities/setup_requirement.dart';
import 'package:moment/features/home_setup/domain/entities/user_setup_metadata.dart';
import 'package:moment/features/home_setup/domain/repositories/user_setup_repository.dart';
import 'package:moment/features/home_setup/domain/services/widget_reminder_policy.dart';
import 'package:moment/features/home_setup/presentation/cubit/home_setup_cubit.dart';
import 'package:moment/features/home_setup/presentation/cubit/home_setup_state.dart';

class _MockFriendsRepository extends Mock implements FriendsRepository {}

class _MockUserSetupRepository extends Mock implements UserSetupRepository {}

class _MockSessionCubit extends Mock implements SessionCubit {}

void main() {
  late _MockFriendsRepository friendsRepository;
  late _MockUserSetupRepository userSetupRepository;
  late _MockSessionCubit sessionCubit;
  late HomeSetupCubit cubit;

  setUp(() {
    friendsRepository = _MockFriendsRepository();
    userSetupRepository = _MockUserSetupRepository();
    sessionCubit = _MockSessionCubit();
    when(() => sessionCubit.state).thenReturn(
      const SessionState(status: SessionStatus.authenticated),
    );
    when(() => sessionCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => sessionCubit.close()).thenAnswer((_) async {});

    cubit = HomeSetupCubit(
      friendsRepository,
      userSetupRepository,
      sessionCubit,
      const WidgetReminderPolicy(),
      () => 'user-1',
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  blocTest<HomeSetupCubit, HomeSetupState>(
    'requires friends when count is zero',
    build: () {
      when(() => friendsRepository.countAcceptedFriends())
          .thenAnswer((_) async => const Success(0));
      return cubit;
    },
    act: (c) => c.onHomeOpened(),
    expect: () => [
      isA<HomeSetupState>().having(
        (s) => s.status,
        'status',
        HomeSetupStatus.checking,
      ),
      isA<HomeSetupState>()
          .having((s) => s.requirement, 'requirement', SetupRequirement.friendsRequired)
          .having((s) => s.acceptedFriendsCount, 'count', 0),
    ],
  );

  blocTest<HomeSetupCubit, HomeSetupState>(
    'skips friend sheet when user has friends and widget confirmed',
    build: () {
      when(() => friendsRepository.countAcceptedFriends())
          .thenAnswer((_) async => const Success(3));
      when(() => userSetupRepository.getMetadata()).thenAnswer(
        (_) async => const Success(
          UserSetupMetadata(
            widgetReminderDismissedCount: 0,
            widgetSetupConfirmed: true,
          ),
        ),
      );
      return cubit;
    },
    act: (c) => c.onHomeOpened(),
    skip: 1,
    expect: () => [
      isA<HomeSetupState>()
          .having((s) => s.requirement, 'requirement', SetupRequirement.none)
          .having((s) => s.acceptedFriendsCount, 'count', 3),
    ],
  );

  blocTest<HomeSetupCubit, HomeSetupState>(
    'does not require friends on network failure',
    build: () {
      when(() => friendsRepository.countAcceptedFriends()).thenAnswer(
        (_) async => const Failed(NetworkFailure()),
      );
      return cubit;
    },
    act: (c) => c.onHomeOpened(),
    skip: 1,
    expect: () => [
      isA<HomeSetupState>()
          .having((s) => s.requirement, 'requirement', SetupRequirement.checkFailed)
          .having((s) => s.status, 'status', HomeSetupStatus.failed),
    ],
  );

  blocTest<HomeSetupCubit, HomeSetupState>(
    'shows celebration when graduating from mandatory friend setup',
    build: () {
      when(() => friendsRepository.countAcceptedFriends())
          .thenAnswer((_) async => const Success(1));
      return cubit;
    },
    seed: () => const HomeSetupState(
      status: HomeSetupStatus.ready,
      requirement: SetupRequirement.friendsRequired,
      acceptedFriendsCount: 0,
    ),
    act: (c) => c.refreshAfterFriendshipChange(),
    expect: () => [
      isA<HomeSetupState>().having(
        (s) => s.requirement,
        'requirement',
        SetupRequirement.friendConnectedCelebration,
      ),
    ],
  );

  blocTest<HomeSetupCubit, HomeSetupState>(
    'shows widget reminder when friends exist and widget missing',
    build: () {
      when(() => friendsRepository.countAcceptedFriends())
          .thenAnswer((_) async => const Success(1));
      when(() => userSetupRepository.getMetadata()).thenAnswer(
        (_) async => const Success(UserSetupMetadata.empty),
      );
      return cubit;
    },
    act: (c) => c.onHomeOpened(),
    skip: 1,
    expect: () => [
      isA<HomeSetupState>().having(
        (s) => s.requirement,
        'requirement',
        SetupRequirement.widgetReminder,
      ),
    ],
  );
}
