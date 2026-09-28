import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/app/lifecycle/session_cubit.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/home_setup/domain/entities/setup_requirement.dart';
import 'package:moment/features/home_setup/domain/entities/user_setup_metadata.dart';
import 'package:moment/features/home_setup/domain/repositories/user_setup_repository.dart';
import 'package:moment/features/home_setup/domain/services/widget_reminder_policy.dart';
import 'package:moment/features/home_setup/presentation/cubit/home_setup_state.dart';

class HomeSetupCubit extends Cubit<HomeSetupState> {
  HomeSetupCubit(
    this._friendsRepository,
    this._userSetupRepository,
    this._sessionCubit,
    this._policy,
    this._userIdProvider,
  ) : super(const HomeSetupState()) {
    _sessionSub = _sessionCubit.stream.listen(_onSessionChanged);
    _onSessionChanged(_sessionCubit.state);
  }

  final FriendsRepository _friendsRepository;
  final UserSetupRepository _userSetupRepository;
  final SessionCubit _sessionCubit;
  final WidgetReminderPolicy _policy;
  final String? Function() _userIdProvider;
  StreamSubscription<SessionState>? _sessionSub;

  var _checkInFlight = false;

  @override
  Future<void> close() {
    unawaited(_sessionSub?.cancel());
    return super.close();
  }

  void _onSessionChanged(SessionState session) {
    if (!session.isAuthenticated) {
      emit(const HomeSetupState());
      return;
    }
    final userId = _userIdProvider();
    if (userId != state.checkedUserId) {
      emit(HomeSetupState(checkedUserId: userId));
    }
  }

  Future<void> onHomeOpened() async {
    if (!_sessionCubit.state.isAuthenticated) return;
    if (_checkInFlight) return;
    _checkInFlight = true;
    emit(
      state.copyWith(
        status: HomeSetupStatus.checking,
        clearError: true,
        sheetVisible: false,
      ),
    );

    try {
      await _evaluateSetup();
    } finally {
      _checkInFlight = false;
    }
  }

  Future<void> refreshAfterFriendshipChange() async {
    if (!_sessionCubit.state.isAuthenticated) return;
    await _evaluateSetup();
  }

  Future<void> retry() => onHomeOpened();

  void onSheetPresented() {
    if (!state.sheetVisible) {
      emit(state.copyWith(sheetVisible: true));
    }
  }

  void onSheetClosed() {
    emit(state.copyWith(sheetVisible: false));
  }

  Future<void> onWidgetMaybeLater() async {
    await _userSetupRepository.recordWidgetReminderDismissed();
    emit(
      state.copyWith(
        requirement: SetupRequirement.none,
        sheetVisible: false,
      ),
    );
  }

  Future<void> onWidgetSetupConfirmed() async {
    await _userSetupRepository.markWidgetSetupConfirmed();
    emit(
      state.copyWith(
        requirement: SetupRequirement.none,
        sheetVisible: false,
      ),
    );
  }

  Future<void> onWidgetReminderShown() async {
    await _userSetupRepository.markWidgetReminderShown(DateTime.now().toUtc());
  }

  Future<void> onFriendConnectedCelebrationCompleted() async {
    emit(
      state.copyWith(
        requirement: SetupRequirement.none,
        sheetVisible: false,
      ),
    );
    await _evaluateSetup();
  }

  Future<void> _evaluateSetup() async {
    final countResult = await _friendsRepository.countAcceptedFriends();
    if (countResult is Failed<int>) {
      emit(
        state.copyWith(
          status: HomeSetupStatus.failed,
          requirement: SetupRequirement.checkFailed,
          errorMessage: countResult.failure.message,
          sheetVisible: false,
        ),
      );
      return;
    }

    final count = (countResult as Success<int>).value;
    if (count < 1) {
      emit(
        state.copyWith(
          status: HomeSetupStatus.ready,
          requirement: SetupRequirement.friendsRequired,
          acceptedFriendsCount: count,
          sheetVisible: false,
        ),
      );
      return;
    }

    if (state.requirement == SetupRequirement.friendsRequired) {
      emit(
        state.copyWith(
          status: HomeSetupStatus.ready,
          requirement: SetupRequirement.friendConnectedCelebration,
          acceptedFriendsCount: count,
          sheetVisible: false,
        ),
      );
      return;
    }

    final metadataResult = await _userSetupRepository.getMetadata();
    if (metadataResult is Failed<UserSetupMetadata>) {
      emit(
        state.copyWith(
          status: HomeSetupStatus.ready,
          requirement: SetupRequirement.none,
          acceptedFriendsCount: count,
          sheetVisible: false,
        ),
      );
      return;
    }

    final metadata = (metadataResult as Success<UserSetupMetadata>).value;

    final showWidget = _policy.shouldShowOnHome(
      metadata: metadata,
      now: DateTime.now().toUtc(),
    );

    emit(
      state.copyWith(
        status: HomeSetupStatus.ready,
        requirement:
            showWidget ? SetupRequirement.widgetReminder : SetupRequirement.none,
        acceptedFriendsCount: count,
        sheetVisible: false,
      ),
    );
  }
}
