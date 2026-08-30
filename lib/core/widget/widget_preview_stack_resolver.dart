import 'package:moment/core/result/result.dart';
import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/core/widget/widget_display_resolver.dart';
import 'package:moment/core/widgets/widget_moment_stack.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/moments/domain/repositories/moment_repository.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';

/// Builds live home-widget stack preview cards from received moments.
Future<List<WidgetStackPreviewMoment>> buildWidgetPreviewStack({
  required List<Moment> moments,
  required WidgetPreferences preferences,
  required CircleRepository circles,
  required int streakCount,
}) async {
  if (moments.isEmpty) return const [];

  final cards = <WidgetStackPreviewMoment>[];
  for (final moment in moments.take(5)) {
    final display = await resolveWidgetDisplay(
      preferences: preferences,
      moment: moment,
      circles: circles,
    );
    cards.add(
      WidgetStackPreviewMoment(
        id: moment.id,
        title: display.headerTitle,
        relativeTime: relativeTimeAgo(moment.createdAt),
        streakCount: streakCount,
        imageUrl: moment.imageUrl,
      ),
    );
  }
  return cards;
}

/// Fetches widget moments + streak for preview surfaces.
Future<({List<WidgetStackPreviewMoment> stack, int streakCount})>
    loadWidgetPreviewStack({
  required MomentRepository moments,
  required WidgetPreferences preferences,
  required CircleRepository circles,
}) async {
  final streakCount = switch (await moments.getMomentStreak()) {
    Success(:final value) => value,
    Failed() => 0,
  };

  final momentsResult = await moments.getWidgetMoments(preferences);
  final list = switch (momentsResult) {
    Success(:final value) => value,
    Failed() => const <Moment>[],
  };

  final stack = await buildWidgetPreviewStack(
    moments: list,
    preferences: preferences,
    circles: circles,
    streakCount: streakCount,
  );

  return (stack: stack, streakCount: streakCount);
}
