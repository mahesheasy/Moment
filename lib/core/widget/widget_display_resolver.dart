import 'package:moment/core/result/result.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';

class WidgetDisplayInfo {
  const WidgetDisplayInfo({
    required this.headerTitle,
    this.headerEmoji = '',
  });

  final String headerTitle;
  final String headerEmoji;
}

Future<WidgetDisplayInfo> resolveWidgetDisplay({
  required WidgetPreferences preferences,
  required Moment moment,
  required CircleRepository circles,
}) async {
  if (preferences.widgetMode == WidgetMode.circle &&
      preferences.selectedCircleId != null) {
    final result = await circles.getCircle(preferences.selectedCircleId!);
    if (result case Success(:final value)) {
      return WidgetDisplayInfo(
        headerTitle: value.name,
        headerEmoji: value.displayEmoji,
      );
    }
  }

  return WidgetDisplayInfo(
    headerTitle: moment.sender.displayName,
    headerEmoji: preferences.theme.emoji,
  );
}
