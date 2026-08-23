import 'package:equatable/equatable.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class DailyPrompt extends Equatable {
  const DailyPrompt({
    required this.id,
    required this.promptDate,
    required this.promptText,
    required this.createdAt,
  });

  final String id;
  final DateTime promptDate;
  final String promptText;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, promptDate, promptText, createdAt];
}

class PromptResponse extends Equatable {
  const PromptResponse({
    required this.id,
    required this.promptId,
    required this.circleId,
    required this.user,
    required this.moment,
    required this.createdAt,
  });

  final String id;
  final String promptId;
  final String circleId;
  final UserProfile user;
  final Moment moment;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, promptId, circleId, user, moment, createdAt];
}

class PromptTodaySummary extends Equatable {
  const PromptTodaySummary({required this.prompt, required this.responses});

  final DailyPrompt prompt;
  final List<PromptResponse> responses;

  int get responseCount => responses.length;

  bool hasUserResponded(String userId) {
    return responses.any((response) => response.user.id == userId);
  }

  @override
  List<Object?> get props => [prompt, responses];
}

class RecordPromptResponseInput extends Equatable {
  const RecordPromptResponseInput({
    required this.promptId,
    required this.circleId,
    required this.momentId,
  });

  final String promptId;
  final String circleId;
  final String momentId;

  @override
  List<Object?> get props => [promptId, circleId, momentId];
}
