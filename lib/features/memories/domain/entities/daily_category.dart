import 'package:equatable/equatable.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

enum DailyCategoryKind { person, circle }

class DailyCategory extends Equatable {
  const DailyCategory({
    required this.id,
    required this.title,
    required this.kind,
    required this.moments,
    this.emoji,
    this.avatarUrl,
    this.subtitle,
  });

  final String id;
  final String title;
  final DailyCategoryKind kind;
  final List<Moment> moments;
  final String? emoji;
  final String? avatarUrl;
  final String? subtitle;

  Moment get cover => moments.first;

  @override
  List<Object?> get props => [
    id,
    title,
    kind,
    moments,
    emoji,
    avatarUrl,
    subtitle,
  ];
}

/// Family/squad circles become their own rails. Each remaining friend
/// becomes a person rail so one sender is one category.
List<DailyCategory> buildDailyCategories({
  required List<Moment> moments,
  required List<Circle> circles,
  required Map<String, List<UserProfile>> membersByCircle,
}) {
  if (moments.isEmpty) return const [];

  final categories = <DailyCategory>[];
  final claimed = <String>{};

  for (final circle in circles) {
    final memberIds = {
      for (final member in membersByCircle[circle.id] ?? const <UserProfile>[])
        member.id,
    };
    if (memberIds.isEmpty) continue;

    final inCircle = moments
        .where((moment) => memberIds.contains(moment.sender.id))
        .toList();
    if (inCircle.isEmpty) continue;

    categories.add(
      DailyCategory(
        id: 'circle:${circle.id}',
        title: circle.name,
        kind: DailyCategoryKind.circle,
        emoji: circle.displayEmoji,
        subtitle:
            '${inCircle.length} ${inCircle.length == 1 ? 'moment' : 'moments'}',
        moments: inCircle,
      ),
    );
    claimed.addAll(inCircle.map((moment) => moment.id));
  }

  final leftover = moments.where((moment) => !claimed.contains(moment.id));
  final bySender = <String, List<Moment>>{};
  for (final moment in leftover) {
    bySender.putIfAbsent(moment.sender.id, () => []).add(moment);
  }

  final people = bySender.values.toList()
    ..sort((a, b) => b.first.createdAt.compareTo(a.first.createdAt));

  for (final group in people) {
    final sender = group.first.sender;
    categories.add(
      DailyCategory(
        id: 'person:${sender.id}',
        title: sender.displayName,
        kind: DailyCategoryKind.person,
        avatarUrl: sender.avatarUrl,
        subtitle: '${group.length} ${group.length == 1 ? 'moment' : 'moments'}',
        moments: group,
      ),
    );
  }

  return categories;
}
