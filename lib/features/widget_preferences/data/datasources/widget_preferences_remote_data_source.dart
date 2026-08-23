import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/errors/postgrest_mapper.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WidgetPreferencesRemoteDataSource {
  WidgetPreferencesRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<WidgetPreferencesBundle> getPreferences() async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'get_widget_preferences',
    );
    return _mapBundle(data);
  }

  Future<WidgetPreferencesBundle> savePreferences(
    WidgetPreferences preferences,
  ) async {
    final payload = preferences.toUpsertJson();
    final data = await _client.rpc<Map<String, dynamic>>(
      'upsert_widget_preferences',
      params: payload,
    );
    return _mapBundle(data);
  }

  Future<WidgetPreferencesBundle> savePrivacy(
    WidgetPreferences preferences,
  ) async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'upsert_widget_privacy',
      params: preferences.toPrivacyJson(),
    );
    return _mapBundle(data);
  }

  WidgetPreferencesBundle _mapBundle(Map<String, dynamic> data) {
    final prefsJson = Map<String, dynamic>.from(data['preferences'] as Map);
    final savedJson = data['saved_preferences'];
    return WidgetPreferencesBundle(
      preferences: WidgetPreferences.fromJson(prefsJson),
      isPremium: data['is_premium'] as bool? ?? false,
      themes: _mapThemes(data['themes'] as List? ?? const []),
      typographyOptions: _mapTypography(
        data['typography_options'] as List? ?? const [],
      ),
      widgetModes: _mapModes(data['widget_modes'] as List? ?? const []),
      savedPreferences: savedJson == null
          ? null
          : WidgetPreferences.fromJson(
              Map<String, dynamic>.from(savedJson as Map),
            ),
    );
  }

  List<WidgetTheme> _mapThemes(List<dynamic> values) {
    return values
        .map((value) => WidgetTheme.fromValue(value as String))
        .toList();
  }

  List<WidgetTypography> _mapTypography(List<dynamic> values) {
    return values
        .map((value) => WidgetTypography.fromValue(value as String))
        .toList();
  }

  List<WidgetMode> _mapModes(List<dynamic> values) {
    return values
        .map((value) => WidgetMode.fromValue(value as String))
        .toList();
  }

  Failure mapError(Object error) {
    if (error is PostgrestException) {
      if (error.message.contains('Moment+ required')) {
        return mapPostgrestError(
          error,
          fallback: 'Moment+ required for premium widgets.',
        );
      }
      return mapPostgrestError(
        error,
        fallback: 'Could not load widget settings. Please try again.',
      );
    }
    if (error is Failure) return error;
    return UnknownFailure(cause: error);
  }
}
