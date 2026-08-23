import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/prompts/domain/entities/daily_prompt.dart';

void main() {
  final prompt = DailyPrompt(
    id: 'p1',
    promptDate: DateTime.utc(2026, 8, 15),
    promptText: 'Show us your view.',
    createdAt: DateTime.utc(2026, 8, 15),
  );

  test('PromptTodaySummary responseCount matches responses length', () {
    final summary = PromptTodaySummary(prompt: prompt, responses: const []);

    expect(summary.responseCount, 0);
  });

  test('PromptTodaySummary hasUserResponded detects user', () {
    final summary = PromptTodaySummary(prompt: prompt, responses: const []);

    expect(summary.hasUserResponded('user-1'), isFalse);
  });
}
