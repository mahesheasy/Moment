import 'dart:async';

import 'package:moment/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef MomentRealtimeCallback = void Function();

class MomentRealtimeSubscriber {
  MomentRealtimeSubscriber(this._client, this._userIdProvider, this._logger);

  final SupabaseClient _client;
  final String? Function() _userIdProvider;
  final AppLogger _logger;

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  MomentRealtimeCallback? _onNewMoment;

  void listen(MomentRealtimeCallback onNewMoment) {
    _onNewMoment = onNewMoment;
    _restart();
  }

  void _restart() {
    _subscription?.cancel();
    _subscription = null;

    final userId = _userIdProvider();
    if (userId == null || _onNewMoment == null) return;

    _subscription = _client
        .from('moment_recipients')
        .stream(primaryKey: ['moment_id', 'recipient_id'])
        .eq('recipient_id', userId)
        .listen(
          (_) => _onNewMoment?.call(),
          onError: (Object error) {
            _logger.warn(
              'Moment realtime stream error',
              context: {'error': error},
            );
          },
        );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _onNewMoment = null;
  }
}
