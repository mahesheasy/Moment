import 'package:moment/core/result/result.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';

abstract class MomentRepository {
  Future<Result<Moment?>> getLatestReceivedMoment();

  Future<Result<Moment?>> getWidgetMoment(WidgetPreferences preferences);

  Future<Result<List<Moment>>> getWidgetMoments(
    WidgetPreferences preferences, {
    int limit = 5,
  });

  Future<Result<Moment>> getMoment(String id);

  Future<Result<List<Moment>>> listReceivedMoments({
    int limit = 20,
    int offset = 0,
    MomentSeenFilter seenFilter = MomentSeenFilter.all,
  });

  Future<Result<List<Moment>>> listSentMoments({
    int limit = 40,
    int offset = 0,
  });

  Future<Result<List<Moment>>> listMomentsSharedToCircle(String circleId);

  Future<Result<Moment>> createMoment(CreateMomentInput input);

  Future<Result<void>> markSeen(String momentId);

  Future<Result<void>> removeFromFeed(String momentId);

  Future<Result<void>> deleteSentMoment(String momentId);

  Future<Result<int>> getMomentStreak();
}
