import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/memories/domain/entities/memory.dart';
import 'package:moment/features/memories/domain/repositories/memory_repository.dart';
import 'package:moment/features/prompts/domain/entities/daily_prompt.dart';
import 'package:moment/features/prompts/domain/repositories/prompt_repository.dart';

enum PromptStatus { initial, loading, loaded, failure }

class PromptState extends Equatable {
  const PromptState({
    this.status = PromptStatus.initial,
    this.prompt,
    this.circles = const [],
    this.errorMessage,
  });

  final PromptStatus status;
  final DailyPrompt? prompt;
  final List<Circle> circles;
  final String? errorMessage;

  PromptState copyWith({
    PromptStatus? status,
    DailyPrompt? prompt,
    List<Circle>? circles,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PromptState(
      status: status ?? this.status,
      prompt: prompt ?? this.prompt,
      circles: circles ?? this.circles,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, prompt, circles, errorMessage];
}

class PromptCubit extends Cubit<PromptState> {
  PromptCubit(this._prompts, this._circles) : super(const PromptState());

  final PromptRepository _prompts;
  final CircleRepository _circles;

  Future<void> loadToday() async {
    emit(state.copyWith(status: PromptStatus.loading, clearError: true));

    final promptResult = await _prompts.getTodaysPrompt();
    final circlesResult = await _circles.getMyCircles();

    switch (promptResult) {
      case Success(:final value):
        final circles = switch (circlesResult) {
          Success(:final value) => value,
          Failed() => const <Circle>[],
        };
        emit(
          state.copyWith(
            status: PromptStatus.loaded,
            prompt: value,
            circles: circles,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: PromptStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }
}

enum CircleTodayStatus { initial, loading, loaded, acting, saving, failure }

class CircleTodayState extends Equatable {
  const CircleTodayState({
    this.status = CircleTodayStatus.initial,
    this.summary,
    this.circleName,
    this.circleEmoji,
    this.hasResponded = false,
    this.errorMessage,
    this.actionMessage,
  });

  final CircleTodayStatus status;
  final PromptTodaySummary? summary;
  final String? circleName;
  final String? circleEmoji;
  final bool hasResponded;
  final String? errorMessage;
  final String? actionMessage;

  CircleTodayState copyWith({
    CircleTodayStatus? status,
    PromptTodaySummary? summary,
    String? circleName,
    String? circleEmoji,
    bool? hasResponded,
    String? errorMessage,
    String? actionMessage,
    bool clearError = false,
    bool clearAction = false,
  }) {
    return CircleTodayState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      circleName: circleName ?? this.circleName,
      circleEmoji: circleEmoji ?? this.circleEmoji,
      hasResponded: hasResponded ?? this.hasResponded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      actionMessage: clearAction ? null : actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    summary,
    circleName,
    circleEmoji,
    hasResponded,
    errorMessage,
    actionMessage,
  ];
}

class CircleTodayCubit extends Cubit<CircleTodayState> {
  CircleTodayCubit(this._prompts, this._circles, this._memories, this._circleId)
    : super(const CircleTodayState());

  final PromptRepository _prompts;
  final CircleRepository _circles;
  final MemoryRepository _memories;
  final String _circleId;

  Future<void> load() async {
    emit(state.copyWith(status: CircleTodayStatus.loading, clearError: true));

    final summaryResult = await _prompts.getCircleTodaySummary(_circleId);
    final circleResult = await _circles.getCircle(_circleId);

    switch (summaryResult) {
      case Success(:final value):
        final respondedResult = await _prompts.hasUserResponded(
          promptId: value.prompt.id,
          circleId: _circleId,
        );
        final hasResponded = switch (respondedResult) {
          Success(:final value) => value,
          Failed() => false,
        };
        final circle = switch (circleResult) {
          Success(:final value) => value,
          Failed() => null,
        };
        emit(
          state.copyWith(
            status: CircleTodayStatus.loaded,
            summary: value,
            circleName: circle?.name,
            circleEmoji: circle?.displayEmoji,
            hasResponded: hasResponded,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CircleTodayStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<MemorySummary?> saveAsMemory(String title) async {
    final summary = state.summary;
    if (summary == null || summary.responses.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Add prompt responses before saving a memory.',
        ),
      );
      return null;
    }

    emit(state.copyWith(status: CircleTodayStatus.saving, clearError: true));
    final result = await _memories.createFromPromptResponses(
      CreateMemoryFromPromptInput(
        title: title,
        circleId: _circleId,
        promptId: summary.prompt.id,
      ),
    );

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: CircleTodayStatus.loaded,
            actionMessage: 'Memory saved.',
          ),
        );
        return value;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CircleTodayStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return null;
    }
  }
}
