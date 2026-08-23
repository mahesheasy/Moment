import 'package:moment/core/result/result.dart';
import 'package:moment/features/time_travel/domain/entities/time_travel_entry.dart';

abstract class TimeTravelRepository {
  Future<Result<List<TimeTravelEntry>>> getTimeTravelEntries();
}
