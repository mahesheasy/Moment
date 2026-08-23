import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/memories/domain/entities/memory.dart';
import 'package:moment/features/memories/domain/entities/memory_theme.dart';

void main() {
  test('MemorySummary dateRangeLabel formats range', () {
    final memory = MemorySummary(
      id: '1',
      title: 'Our Summer',
      ownerId: 'owner',
      momentCount: 5,
      participantCount: 2,
      dayCount: 3,
      createdAt: DateTime.utc(2026, 8, 15),
      memoryType: MemoryType.trip,
      theme: MemoryTheme.sunset,
      startsAt: DateTime.utc(2026, 6, 12),
      endsAt: DateTime.utc(2026, 7, 4),
    );

    expect(memory.dateRangeLabel, contains('Jun'));
    expect(memory.dateRangeLabel, contains('Jul'));
  });

  test('MemorySummary memoryDateLabel formats single date', () {
    final memory = MemorySummary(
      id: '1',
      title: 'Birthday',
      ownerId: 'owner',
      momentCount: 1,
      participantCount: 1,
      dayCount: 1,
      createdAt: DateTime.utc(2026, 8, 15),
      memoryType: MemoryType.birthday,
      theme: MemoryTheme.love,
      memoryDate: DateTime.utc(2026, 3, 14),
    );

    expect(memory.memoryDateLabel, contains('Mar'));
    expect(memory.memoryDateLabel, contains('2026'));
  });

  test('MemoryType labels cover advanced memory kinds', () {
    expect(MemoryType.anniversary.label, 'Anniversary');
    expect(MemoryType.prompt.label, 'Prompt');
  });

  test('MemoryDetail groups items by chapter', () {
    final detail = MemoryDetail(
      summary: MemorySummary(
        id: '1',
        title: 'Trip',
        ownerId: 'owner',
        momentCount: 2,
        participantCount: 1,
        dayCount: 1,
        createdAt: DateTime.utc(2026, 8, 15),
        memoryType: MemoryType.trip,
        theme: MemoryTheme.minimal,
      ),
      items: const [],
      participants: const [],
      chapters: const [MemoryChapter(id: 'c1', title: 'Day 1', position: 0)],
    );

    expect(detail.chapters.single.title, 'Day 1');
  });
}
