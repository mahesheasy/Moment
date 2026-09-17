import 'package:moment/features/moments/domain/entities/moment.dart';

/// Selects which Moment the home-screen widget should display.
///
/// Only unread moments appear on the widget. When all are caught up, the widget
/// shows the empty state.
class WidgetMomentSelection {
  const WidgetMomentSelection({this.moment, this.isUnread = false});

  final Moment? moment;
  final bool isUnread;
}

WidgetMomentSelection selectWidgetMoment({
  required List<Moment> unseen,
}) {
  if (unseen.isNotEmpty) {
    final sorted = _sortNewestFirst(unseen);
    return WidgetMomentSelection(moment: sorted.first, isUnread: true);
  }

  return const WidgetMomentSelection();
}

List<Moment> _sortNewestFirst(List<Moment> moments) {
  final sorted = List<Moment>.from(moments)
    ..sort((a, b) {
      final byTime = b.createdAt.compareTo(a.createdAt);
      if (byTime != 0) return byTime;
      return b.id.compareTo(a.id);
    });
  return sorted;
}
