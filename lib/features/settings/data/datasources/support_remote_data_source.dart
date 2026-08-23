import 'package:moment/core/errors/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportRemoteDataSource {
  SupportRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<void> submitReport({
    required String userId,
    required String category,
    required String description,
  }) async {
    await _client.from('support_reports').insert({
      'user_id': userId,
      'category': category,
      'description': description,
    });
  }

  Failure mapError(Object error) {
    if (error is PostgrestException) {
      return DatabaseFailure(cause: error);
    }
    if (error is Failure) return error;
    return UnknownFailure(cause: error);
  }
}
