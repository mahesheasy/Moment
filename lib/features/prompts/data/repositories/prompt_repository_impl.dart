import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/prompts/data/datasources/prompts_remote_data_source.dart';
import 'package:moment/features/prompts/domain/entities/daily_prompt.dart';
import 'package:moment/features/prompts/domain/repositories/prompt_repository.dart';

class PromptRepositoryImpl implements PromptRepository {
  PromptRepositoryImpl(this._remote, this._userIdProvider);

  final PromptsRemoteDataSource _remote;
  final String? Function() _userIdProvider;

  @override
  Future<Result<DailyPrompt>> getTodaysPrompt() async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getTodaysPrompt());
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<PromptTodaySummary>> getCircleTodaySummary(
    String circleId,
  ) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    try {
      final prompt = await _remote.getTodaysPrompt();
      final responses = await _remote.getCircleResponses(
        circleId: circleId,
        promptId: prompt.id,
      );
      return Success(PromptTodaySummary(prompt: prompt, responses: responses));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<bool>> hasUserResponded({
    required String promptId,
    required String circleId,
  }) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(
        await _remote.hasUserResponded(
          promptId: promptId,
          circleId: circleId,
          userId: userId,
        ),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> recordResponse(RecordPromptResponseInput input) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      final alreadyResponded = await _remote.hasUserResponded(
        promptId: input.promptId,
        circleId: input.circleId,
        userId: userId,
      );
      if (alreadyResponded) {
        return const Failed(
          ValidationFailure(
            message: 'You already responded to today\'s prompt.',
          ),
        );
      }

      await _remote.recordResponse(
        promptId: input.promptId,
        circleId: input.circleId,
        userId: userId,
        momentId: input.momentId,
      );
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<String>>> getCircleMemberIds(String circleId) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getCircleMemberIds(circleId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }
}
