import 'package:equatable/equatable.dart';

/// Optional context when opening camera from a circle (with or without daily prompt).
class CameraPromptContext extends Equatable {
  const CameraPromptContext({
    required this.circleId,
    this.promptId,
    this.promptText = '',
  });

  final String circleId;
  final String? promptId;
  final String promptText;

  bool get hasPrompt => promptId != null && promptId!.isNotEmpty;

  @override
  List<Object?> get props => [circleId, promptId, promptText];
}
