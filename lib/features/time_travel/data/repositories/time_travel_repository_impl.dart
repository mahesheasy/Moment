import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/moments/domain/repositories/moment_repository.dart';
import 'package:moment/features/time_travel/data/datasources/time_travel_remote_data_source.dart';
import 'package:moment/features/time_travel/domain/entities/time_travel_entry.dart';
import 'package:moment/features/time_travel/domain/repositories/time_travel_repository.dart';

class TimeTravelRepositoryImpl implements TimeTravelRepository {
  TimeTravelRepositoryImpl(this._remote, this._moments, this._userIdProvider);

  final TimeTravelRemoteDataSource _remote;
  final MomentRepository _moments;
  final String? Function() _userIdProvider;

  @override
  Future<Result<List<TimeTravelEntry>>> getTimeTravelEntries() async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    try {
      final slots = await _remote.getTimeTravelSlots();
      final entries = <TimeTravelEntry>[];

      for (final slot in slots) {
        Moment? moment;
        final momentId = slot.momentId;
        if (momentId != null) {
          final result = await _moments.getMoment(momentId);
          moment = switch (result) {
            Success(:final value) => value,
            Failed() => null,
          };
        }

        if (moment != null) {
          entries.add(
            TimeTravelEntry(
              yearsAgo: slot.yearsAgo,
              targetDate: slot.targetDate,
              moment: moment,
            ),
          );
        }
      }

      entries.sort((a, b) => a.yearsAgo.compareTo(b.yearsAgo));
      return Success(entries);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(UnknownFailure(cause: error));
    }
  }
}
