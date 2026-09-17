import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:moment/app/lifecycle/app_lifecycle_cubit.dart';
import 'package:moment/app/lifecycle/session_cubit.dart';
import 'package:moment/core/logging/app_logger.dart';
import 'package:moment/features/profile/data/datasources/profile_remote_data_source.dart';

/// Keeps the signed-in user's [profiles.last_seen_at] fresh while the app is active.
class ProfilePresenceService {
  ProfilePresenceService(
    this._profileRemote,
    this._sessionCubit,
    this._lifecycleCubit,
    this._logger,
  );

  final ProfileRemoteDataSource _profileRemote;
  final SessionCubit _sessionCubit;
  final AppLifecycleCubit _lifecycleCubit;
  final AppLogger _logger;

  static const _heartbeatInterval = Duration(seconds: 30);

  StreamSubscription<SessionState>? _sessionSub;
  StreamSubscription<AppLifecycleStateView>? _lifecycleSub;
  Timer? _heartbeat;
  var _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _sessionSub = _sessionCubit.stream.listen(_onSessionChanged);
    _lifecycleSub = _lifecycleCubit.stream.listen(_onLifecycleChanged);

    if (_sessionCubit.state.isAuthenticated) {
      _startHeartbeat();
    }
  }

  void onAuthenticated() {
    _startHeartbeat();
  }

  void _onSessionChanged(SessionState state) {
    if (state.isAuthenticated) {
      _startHeartbeat();
    } else if (state.status == SessionStatus.unauthenticated) {
      _stopHeartbeat();
    }
  }

  void _onLifecycleChanged(AppLifecycleStateView state) {
    if (!_sessionCubit.state.isAuthenticated) return;
    if (state.status == AppLifecycleState.resumed) {
      unawaited(pulse());
    }
  }

  void _startHeartbeat() {
    unawaited(pulse());
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) => pulse());
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  Future<void> pulse() async {
    if (!_sessionCubit.state.isAuthenticated) return;
    try {
      await _profileRemote.touchLastSeen();
    } on Object catch (error, stackTrace) {
      _logger.error('touch_last_seen failed', error: error, stackTrace: stackTrace);
    }
  }

  void dispose() {
    _stopHeartbeat();
    unawaited(_sessionSub?.cancel());
    unawaited(_lifecycleSub?.cancel());
    _sessionSub = null;
    _lifecycleSub = null;
    _started = false;
  }
}
