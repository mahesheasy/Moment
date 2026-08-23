import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/time_travel/domain/entities/time_travel_entry.dart';

void main() {
  test('TimeTravelEntry headline formats years ago', () {
    final oneYear = TimeTravelEntry(
      yearsAgo: 1,
      targetDate: DateTime.utc(2025, 8, 15),
    );
    final twoYears = TimeTravelEntry(
      yearsAgo: 2,
      targetDate: DateTime.utc(2024, 8, 15),
    );

    expect(oneYear.headline, '1 YEAR AGO');
    expect(twoYears.headline, '2 YEARS AGO');
  });

  test('TimeTravelEntry formattedDate renders long date', () {
    final entry = TimeTravelEntry(
      yearsAgo: 2,
      targetDate: DateTime.utc(2024, 8, 15),
    );

    expect(entry.formattedDate, contains('August'));
    expect(entry.formattedDate, contains('2024'));
  });
}
