import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/errors/postgrest_mapper.dart';
import 'package:moment/features/home_setup/domain/entities/user_setup_metadata.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserSetupRemoteDataSource {
  UserSetupRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<UserSetupMetadata> fetchOrCreate(String userId) async {
    final existing = await _client
        .from('user_setup_state')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      return _map(Map<String, dynamic>.from(existing));
    }

    final inserted = await _client
        .from('user_setup_state')
        .insert({'user_id': userId})
        .select()
        .single();

    return _map(Map<String, dynamic>.from(inserted));
  }

  Future<UserSetupMetadata> update(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    final data = await _client
        .from('user_setup_state')
        .update({
          ...patch,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .select()
        .single();
    return _map(Map<String, dynamic>.from(data));
  }

  UserSetupMetadata _map(Map<String, dynamic> row) {
    final lastShownRaw = row['widget_reminder_last_shown_at'] as String?;
    return UserSetupMetadata(
      widgetReminderLastShownAt: lastShownRaw == null
          ? null
          : DateTime.parse(lastShownRaw).toUtc(),
      widgetReminderDismissedCount:
          (row['widget_reminder_dismissed_count'] as num?)?.toInt() ?? 0,
      widgetSetupConfirmed: row['widget_setup_confirmed'] as bool? ?? false,
    );
  }

  Failure mapError(Object error) {
    return mapPostgrestError(
      error,
      fallback: 'Could not load setup preferences. Please try again.',
    );
  }
}
