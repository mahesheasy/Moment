import 'package:moment/core/errors/failures.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';
import 'package:moment/features/profile/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialRemoteDataSource {
  SocialRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<MomentReactionSummary> getReactionSummary(
    String momentId,
    String userId,
  ) async {
    final data = await _client
        .from('moment_reactions')
        .select('reaction, user_id')
        .eq('moment_id', momentId);

    final counts = <ReactionType, int>{};
    ReactionType? myReaction;

    for (final row in data as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final type = ReactionType.fromValue(map['reaction'] as String);
      if (type == null) continue;
      counts[type] = (counts[type] ?? 0) + 1;
      if (map['user_id'] == userId) {
        myReaction = type;
      }
    }

    return MomentReactionSummary(counts: counts, myReaction: myReaction);
  }

  Future<void> react({
    required String momentId,
    required String userId,
    required ReactionType reaction,
  }) async {
    await _client.from('moment_reactions').upsert({
      'moment_id': momentId,
      'user_id': userId,
      'reaction': reaction.value,
    }, onConflict: 'moment_id,user_id');
  }

  Future<void> removeReaction({
    required String momentId,
    required String userId,
  }) async {
    await _client
        .from('moment_reactions')
        .delete()
        .eq('moment_id', momentId)
        .eq('user_id', userId);
  }

  Future<void> sendPing({
    required String senderId,
    required String recipientId,
    String? momentId,
    String emoji = '👋',
  }) async {
    await _client.from('pings').insert({
      'sender_id': senderId,
      'recipient_id': recipientId,
      'emoji': emoji,
      if (momentId != null) 'moment_id': momentId,
    });
  }

  Future<List<PingActivity>> listRecentPings(String userId) async {
    final data = await _client
        .from('pings')
        .select(
          'id, sender_id, recipient_id, emoji, created_at, sender:sender_id(*), recipient:recipient_id(*)',
        )
        .or('sender_id.eq.$userId,recipient_id.eq.$userId')
        .order('created_at', ascending: false)
        .limit(20);

    return (data as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final sender = ProfileModel.fromJson(
        Map<String, dynamic>.from(map['sender'] as Map),
      ).toEntity();
      final recipient = ProfileModel.fromJson(
        Map<String, dynamic>.from(map['recipient'] as Map),
      ).toEntity();
      final sentByMe = map['sender_id'] == userId;
      return PingActivity(
        id: map['id'] as String,
        counterpart: sentByMe ? recipient : sender,
        sentByMe: sentByMe,
        emoji: (map['emoji'] as String?)?.trim().isNotEmpty == true
            ? map['emoji'] as String
            : '👋',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();
  }

  Failure mapError(Object error) {
    if (error is PostgrestException) {
      return DatabaseFailure(cause: error);
    }
    if (error is Failure) return error;
    return UnknownFailure(cause: error);
  }
}
