import 'package:flutter_test/flutter_test.dart';
import 'package:moment/core/utils/relative_time.dart';

void main() {
  final now = DateTime.utc(2026, 8, 22, 12);

  test('relativeTimeAgo formats recent times', () {
    expect(relativeTimeAgo(now, now: now), 'now');
    expect(
      relativeTimeAgo(now.subtract(const Duration(minutes: 2)), now: now),
      '2m ago',
    );
    expect(
      relativeTimeAgo(now.subtract(const Duration(hours: 3)), now: now),
      '3h ago',
    );
    expect(
      relativeTimeAgo(now.subtract(const Duration(days: 4)), now: now),
      '4d ago',
    );
  });

  test('relativeTimeAgo compares in UTC so local clocks stay honest', () {
    final localNow = DateTime(2026, 8, 22, 17, 30);
    final sentUtc = DateTime.utc(2026, 8, 22, 11, 30);
    expect(relativeTimeAgo(sentUtc, now: localNow), '30m ago');
  });
}
