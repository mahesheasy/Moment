String relativeTimeAgo(DateTime time, {DateTime? now}) {
  final clock = (now ?? DateTime.now()).toUtc();
  final then = time.toUtc();
  final diff = clock.difference(then);
  if (diff.isNegative || diff.inSeconds < 45) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
  return '${diff.inDays ~/ 30}mo ago';
}
