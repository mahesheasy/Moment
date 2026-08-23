import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/moments/data/datasources/social_remote_data_source.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';
import 'package:moment/features/moments/domain/repositories/social_repository.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl(this._remote, this._userIdProvider);

  final SocialRemoteDataSource _remote;
  final String? Function() _userIdProvider;

  @override
  Future<Result<MomentReactionSummary>> getReactionSummary(
    String momentId,
  ) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getReactionSummary(momentId, userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> react({
    required String momentId,
    required ReactionType reaction,
  }) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.react(
        momentId: momentId,
        userId: userId,
        reaction: reaction,
      );
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> removeReaction(String momentId) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.removeReaction(momentId: momentId, userId: userId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> sendPing({
    required String recipientId,
    String? momentId,
    String emoji = '👋',
  }) async {
    final senderId = _userIdProvider();
    if (senderId == null) return const Failed(AuthenticationFailure());
    if (senderId == recipientId) {
      return const Failed(
        ValidationFailure(message: 'You cannot ping yourself.'),
      );
    }

    try {
      await _remote.sendPing(
        senderId: senderId,
        recipientId: recipientId,
        momentId: momentId,
        emoji: emoji,
      );
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<PingActivity>>> listRecentPings() async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.listRecentPings(userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }
}
