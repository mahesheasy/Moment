import 'package:moment/core/logging/app_logger.dart';
import 'package:moment/core/push/push_bridge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the device's FCM token associated with the signed-in Supabase user.
class PushRegistrationService {
  PushRegistrationService(this._bridge, this._client, this._logger);

  final PushBridge _bridge;
  final SupabaseClient _client;
  final AppLogger _logger;

  String? _registeredToken;

  Future<void> register() async {
    try {
      if (_client.auth.currentSession == null) return;

      if (!await _bridge.hasNotificationPermission()) {
        await _bridge.requestNotificationPermission();
      }

      final token = await _bridge.getToken();
      if (token == null || token.isEmpty) return;
      if (token == _registeredToken) return;

      await _client.rpc<void>(
        'register_device_token',
        params: {'p_token': token, 'p_platform': 'android'},
      );
      _registeredToken = token;
      _logger.info('Registered device for push');
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Could not register device for push',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> unregister() async {
    try {
      if (_client.auth.currentSession == null) {
        _registeredToken = null;
        return;
      }

      final token = _registeredToken ?? await _bridge.getToken();
      if (token != null && token.isNotEmpty) {
        await _client.rpc<void>(
          'remove_device_token',
          params: {'p_token': token},
        );
      }
      _registeredToken = null;
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Could not remove device push registration',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
