/// Parses Postgres / Supabase timestamp values into UTC [DateTime].
DateTime? parseUtcTimestamp(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw.toUtc();
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.parse(trimmed).toUtc();
  }
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
  }
  return null;
}
