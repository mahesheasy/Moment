import 'package:supabase_flutter/supabase_flutter.dart';

class TimeTravelSlot {
  const TimeTravelSlot({
    required this.yearsAgo,
    required this.targetDate,
    this.momentId,
  });

  final int yearsAgo;
  final DateTime targetDate;
  final String? momentId;
}

class TimeTravelRemoteDataSource {
  TimeTravelRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<TimeTravelSlot>> getTimeTravelSlots() async {
    final data = await _client.rpc<List<dynamic>>('get_time_travel_moments');
    return data.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final momentId = map['moment_id'] as String?;
      return TimeTravelSlot(
        yearsAgo: map['years_ago'] as int,
        targetDate: DateTime.parse(map['target_date'] as String),
        momentId: momentId,
      );
    }).toList();
  }
}
