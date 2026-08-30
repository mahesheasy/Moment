import 'package:moment/core/config/app_env.dart';
import 'package:moment/core/logging/app_logger.dart';
import 'package:moment/core/push/push_bridge.dart';
import 'package:moment/core/widget/android_widget_bridge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the device's FCM token associated with the signed-in Supabase user.
class PushRegistrationService {
  PushRegistrationService(
    this._bridge,
    this._client,
    this._logger,
    this._widgetBridge,
    this._env,
  );

  final PushBridge _bridge;
  final SupabaseClient _client;
  final AppLogger _logger;
  final AndroidWidgetBridge _widgetBridge;
  final AppEnv _env;

  String? _registeredToken;

  Future<void> register() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return;

      if (!await _bridge.hasNotificationPermission()) {
        await _bridge.requestNotificationPermission();
      }

      final token = await _bridge.getToken();
      if (token == null || token.isEmpty) return;
      if (token == _registeredToken) {
        await _persistWidgetSyncSession(session);
        return;
      }

      await _client.rpc<void>(
        'register_device_token',
        params: {'p_token': token, 'p_platform': 'android'},
      );
      _registeredToken = token;
      await _persistWidgetSyncSession(session);
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
        await _widgetBridge.clearWidgetSyncSession();
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
      await _widgetBridge.clearWidgetSyncSession();
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Could not remove device push registration',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persistWidgetSyncSession(Session session) async {
    if (_env.supabaseUrl.isEmpty || _env.supabasePublishableKey.isEmpty) return;
    await _widgetBridge.saveWidgetSyncSession(
      supabaseUrl: _env.supabaseUrl,
      supabaseAnonKey: _env.supabasePublishableKey,
      userId: session.user.id,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
  }
}
