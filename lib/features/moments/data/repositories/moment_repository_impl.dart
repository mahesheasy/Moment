import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/moments/data/datasources/moments_remote_data_source.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/moments/domain/repositories/moment_repository.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';

class MomentRepositoryImpl implements MomentRepository {
  MomentRepositoryImpl(this._remote, this._userIdProvider);

  final MomentsRemoteDataSource _remote;
  final String? Function() _userIdProvider;

  @override
  Future<Result<Moment?>> getLatestReceivedMoment() async {
    return getWidgetMoment(WidgetPreferences.defaults());
  }

  @override
  Future<Result<Moment?>> getWidgetMoment(WidgetPreferences preferences) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      final moment = switch (preferences.widgetMode) {
        WidgetMode.latest => await _remote.getLatestReceivedMoment(userId),
        WidgetMode.person =>
          preferences.selectedPersonId == null
              ? null
              : await _remote.getLatestReceivedMomentFromSender(
                  userId: userId,
                  senderId: preferences.selectedPersonId!,
                ),
        WidgetMode.circle =>
          preferences.selectedCircleId == null
              ? null
              : await _remote.getLatestReceivedMomentFromCircle(
                  userId: userId,
                  circleId: preferences.selectedCircleId!,
                ),
      };
      return Success(moment);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<Moment>>> getWidgetMoments(
    WidgetPreferences preferences, {
    int limit = 5,
  }) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      final moments = switch (preferences.widgetMode) {
        WidgetMode.latest => await _remote.listReceivedMoments(
          userId: userId,
          limit: limit,
        ),
        WidgetMode.person =>
          preferences.selectedPersonId == null
              ? <Moment>[]
              : (await _remote.listReceivedMoments(
                  userId: userId,
                  limit: 20,
                ))
                  .where(
                    (moment) => moment.sender.id == preferences.selectedPersonId,
                  )
                  .take(limit)
                  .toList(),
        WidgetMode.circle =>
          preferences.selectedCircleId == null
              ? <Moment>[]
              : await _listCircleWidgetMoments(
                  userId: userId,
                  circleId: preferences.selectedCircleId!,
                  limit: limit,
                ),
      };
      return Success(moments);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  Future<List<Moment>> _listCircleWidgetMoments({
    required String userId,
    required String circleId,
    required int limit,
  }) async {
    final members = await _remote.listCircleMemberIds(circleId);
    final senderIds = members.where((id) => id != userId).toSet();
    if (senderIds.isEmpty) return const [];

    return (await _remote.listReceivedMoments(userId: userId, limit: 20))
        .where((moment) => senderIds.contains(moment.sender.id))
        .take(limit)
        .toList();
  }

  @override
  Future<Result<Moment>> getMoment(String id) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getMoment(id, userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<Moment>>> listReceivedMoments({
    int limit = 20,
    int offset = 0,
    MomentSeenFilter seenFilter = MomentSeenFilter.all,
  }) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(
        await _remote.listReceivedMoments(
          userId: userId,
          limit: limit,
          offset: offset,
          seenFilter: seenFilter,
        ),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<Moment>>> listMomentsSharedToCircle(String circleId) async {
    try {
      return Success(await _remote.listMomentsSharedToCircle(circleId: circleId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<Moment>> createMoment(CreateMomentInput input) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    if (input.recipientIds.isEmpty) {
      return const Failed(
        ValidationFailure(message: 'Choose yourself or at least one friend.'),
      );
    }

    try {
      return Success(
        await _remote.createMoment(
          senderId: userId,
          imageBytes: input.imageBytes,
          mimeType: input.mimeType,
          recipientIds: input.recipientIds,
          caption: input.caption,
          idempotencyKey: input.idempotencyKey,
        ),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> markSeen(String momentId) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.markSeen(momentId: momentId, userId: userId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> removeFromFeed(String momentId) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.removeFromFeed(momentId: momentId, userId: userId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> deleteSentMoment(String momentId) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.deleteSentMoment(momentId: momentId, senderId: userId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }
}
