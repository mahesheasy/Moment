/// Consecutive calendar days with moment activity (send or receive).
int calculateMomentStreak(Iterable<DateTime> activityTimestamps, {DateTime? now}) {
  if (activityTimestamps.isEmpty) return 0;

  final today = _dayOnly(now ?? DateTime.now());
  final days = activityTimestamps.map(_dayOnly).toSet();

  var cursor = today;
  if (!days.contains(cursor)) {
    final yesterday = today.subtract(const Duration(days: 1));
    if (!days.contains(yesterday)) return 0;
    cursor = yesterday;
  }

  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

DateTime _dayOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
