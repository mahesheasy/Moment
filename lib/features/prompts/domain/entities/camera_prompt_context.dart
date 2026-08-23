import 'package:equatable/equatable.dart';

/// Optional context when opening camera to respond to a daily prompt.
class CameraPromptContext extends Equatable {
  const CameraPromptContext({
    required this.promptId,
    required this.circleId,
    required this.promptText,
  });

  final String promptId;
  final String circleId;
  final String promptText;

  @override
  List<Object?> get props => [promptId, circleId, promptText];
}
