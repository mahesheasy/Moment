import 'package:moment/core/errors/failures.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/prompts/domain/entities/daily_prompt.dart';
import 'package:moment/features/profile/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromptsRemoteDataSource {
  PromptsRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const _bucket = 'moments';

  Future<DailyPrompt> getTodaysPrompt() async {
    final data = await _client.rpc<Map<String, dynamic>>('get_todays_prompt');
    return _mapPrompt(data);
  }

  Future<List<PromptResponse>> getCircleResponses({
    required String circleId,
    required String promptId,
  }) async {
    final data = await _client
        .from('prompt_responses')
        .select(
          'id, prompt_id, circle_id, created_at, user:user_id(*), moment:moment_id(*, sender:sender_id(*))',
        )
        .eq('circle_id', circleId)
        .eq('prompt_id', promptId)
        .order('created_at');

    final rows = data as List;
    return Future.wait(
      rows.map((row) => _mapResponse(Map<String, dynamic>.from(row as Map))),
    );
  }

  Future<bool> hasUserResponded({
    required String promptId,
    required String circleId,
    required String userId,
  }) async {
    final data = await _client
        .from('prompt_responses')
        .select('id')
        .eq('prompt_id', promptId)
        .eq('circle_id', circleId)
        .eq('user_id', userId)
        .maybeSingle();
    return data != null;
  }

  Future<void> recordResponse({
    required String promptId,
    required String circleId,
    required String userId,
    required String momentId,
  }) async {
    await _client.from('prompt_responses').insert({
      'prompt_id': promptId,
      'circle_id': circleId,
      'user_id': userId,
      'moment_id': momentId,
    });
  }

  Future<List<String>> getCircleMemberIds(String circleId) async {
    final data = await _client
        .from('circle_members')
        .select('user_id')
        .eq('circle_id', circleId);

    return (data as List)
        .map((row) => (row as Map)['user_id'] as String)
        .toList();
  }

  Future<PromptResponse> _mapResponse(Map<String, dynamic> row) async {
    final map = row;
    final user = ProfileModel.fromJson(
      Map<String, dynamic>.from(map['user'] as Map),
    ).toEntity();
    final momentJson = Map<String, dynamic>.from(map['moment'] as Map);
    final storagePath = momentJson['storage_path'] as String;
    final imageUrl = await _client.storage
        .from(_bucket)
        .createSignedUrl(storagePath, 3600);
    final sender = ProfileModel.fromJson(
      Map<String, dynamic>.from(momentJson['sender'] as Map),
    ).toEntity();

    final moment = Moment(
      id: momentJson['id'] as String,
      sender: sender,
      storagePath: storagePath,
      imageUrl: imageUrl,
      caption: momentJson['caption'] as String?,
      createdAt: DateTime.parse(momentJson['created_at'] as String),
      isSeen: false,
    );

    return PromptResponse(
      id: map['id'] as String,
      promptId: map['prompt_id'] as String,
      circleId: map['circle_id'] as String,
      user: user,
      moment: moment,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DailyPrompt _mapPrompt(Map<String, dynamic> data) {
    return DailyPrompt(
      id: data['id'] as String,
      promptDate: DateTime.parse(data['prompt_date'] as String),
      promptText: data['prompt_text'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  Failure mapError(Object error) {
    if (error is PostgrestException) {
      if (error.code == '23505') {
        return const ValidationFailure(
          message: 'You already responded to today\'s prompt.',
        );
      }
      return DatabaseFailure(cause: error);
    }
    if (error is Failure) return error;
    return UnknownFailure(cause: error);
  }
}
