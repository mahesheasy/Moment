import 'dart:async';

import 'package:moment/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef MomentRealtimeCallback = void Function(String momentId);

/// Streams `moment_recipients` inserts for the signed-in user.
class MomentRealtimeSubscriber {
  MomentRealtimeSubscriber(this._client, this._userIdProvider, this._logger);

  final SupabaseClient _client;
  final String? Function() _userIdProvider;
  final AppLogger _logger;

  RealtimeChannel? _channel;
  MomentRealtimeCallback? _onNewMoment;

  void listen(MomentRealtimeCallback onNewMoment) {
    _onNewMoment = onNewMoment;
    _restart();
  }

  void _restart() {
    final channel = _channel;
    if (channel != null) {
      unawaited(_client.removeChannel(channel));
    }
    _channel = null;

    final userId = _userIdProvider();
    if (userId == null || _onNewMoment == null) return;

    _channel =
        _client
            .channel('widget-moment-inserts-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'moment_recipients',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'recipient_id',
                value: userId,
              ),
              callback: (payload) {
                final momentId = payload.newRecord['moment_id']?.toString();
                if (momentId == null || momentId.isEmpty) return;
                _onNewMoment?.call(momentId);
              },
            )
            .subscribe((status, error) {
              if (error != null) {
                _logger.warn(
                  'Widget moment realtime error',
                  context: {'error': error, 'status': status.name},
                );
              }
            });
  }

  void dispose() {
    final channel = _channel;
    _channel = null;
    _onNewMoment = null;
    if (channel != null) {
      unawaited(_client.removeChannel(channel));
    }
  }
}
