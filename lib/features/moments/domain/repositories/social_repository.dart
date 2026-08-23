import 'package:moment/core/result/result.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';

abstract class SocialRepository {
  Future<Result<MomentReactionSummary>> getReactionSummary(String momentId);

  Future<Result<void>> react({
    required String momentId,
    required ReactionType reaction,
  });

  Future<Result<void>> removeReaction(String momentId);

  Future<Result<void>> sendPing({
    required String recipientId,
    String? momentId,
    String emoji = '👋',
  });

  Future<Result<List<PingActivity>>> listRecentPings();
}
