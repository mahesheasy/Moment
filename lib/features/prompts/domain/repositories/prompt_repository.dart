import 'package:moment/core/result/result.dart';
import 'package:moment/features/prompts/domain/entities/daily_prompt.dart';

abstract class PromptRepository {
  Future<Result<DailyPrompt>> getTodaysPrompt();

  Future<Result<PromptTodaySummary>> getCircleTodaySummary(String circleId);

  Future<Result<bool>> hasUserResponded({
    required String promptId,
    required String circleId,
  });

  Future<Result<void>> recordResponse(RecordPromptResponseInput input);

  Future<Result<List<String>>> getCircleMemberIds(String circleId);
}
