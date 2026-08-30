import 'package:flutter/material.dart';
import 'package:moment/features/friends/presentation/theme/friend_profile_typography.dart';

class FriendProfileStatData {
  const FriendProfileStatData({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class FriendProfileStats extends StatelessWidget {
  const FriendProfileStats({required this.stats, super.key});

  final List<FriendProfileStatData> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _ProfileStatItem(stat: stats[i])),
        ],
      ],
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  const _ProfileStatItem({required this.stat});

  final FriendProfileStatData stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            stat.value,
            maxLines: 1,
            style: FriendProfileTextStyles.statValue,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: FriendProfileTextStyles.statLabel,
        ),
      ],
    );
  }
}

List<FriendProfileStatData> buildFriendProfileStats({
  required bool isFriend,
  required int mutualFriendCount,
  DateTime? friendsSince,
  DateTime? joinedAt,
}) {
  if (!isFriend) return const [];

  final daysTogether = friendsSince == null ? 0 : _daysSince(friendsSince);
  final memberMonths = joinedAt == null ? 0 : _monthsSince(joinedAt);
  final connectMonths = friendsSince == null ? 0 : _monthsSince(friendsSince);

  return [
    FriendProfileStatData(
      value: '$mutualFriendCount',
      label: 'Mutual',
    ),
    FriendProfileStatData(
      value: daysTogether == 0 ? 'Today' : '$daysTogether',
      label: daysTogether == 1 ? 'Day' : 'Days',
    ),
    FriendProfileStatData(
      value: memberMonths == 0 ? 'New' : '$memberMonths',
      label: memberMonths == 1 ? 'Month' : 'Member',
    ),
    FriendProfileStatData(
      value: connectMonths == 0 ? 'New' : '$connectMonths',
      label: connectMonths == 1 ? 'Month' : 'Linked',
    ),
  ];
}

int _daysSince(DateTime since) {
  final now = DateTime.now().toUtc();
  final then = since.toUtc();
  return now.difference(then).inDays.clamp(0, 9999);
}

int _monthsSince(DateTime since) {
  final now = DateTime.now().toUtc();
  final then = since.toUtc();
  return ((now.year - then.year) * 12) + (now.month - then.month);
}
