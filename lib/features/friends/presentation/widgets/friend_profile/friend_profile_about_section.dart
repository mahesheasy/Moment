import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/friends/presentation/theme/friend_profile_typography.dart';

class FriendProfileAboutRow {
  const FriendProfileAboutRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class FriendProfileAboutSection extends StatelessWidget {
  const FriendProfileAboutSection({
    required this.title,
    required this.rows,
    super.key,
  });

  final String title;
  final List<FriendProfileAboutRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: FriendProfileTextStyles.sectionTitle),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < rows.length; i++) ...[
          _AboutRow(row: rows[i]),
          if (i < rows.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.row});

  final FriendProfileAboutRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(row.label, style: FriendProfileTextStyles.aboutLabel),
        ),
        const SizedBox(width: 12),
        Text(row.value, style: FriendProfileTextStyles.aboutValue),
      ],
    );
  }
}

List<FriendProfileAboutRow> buildFriendProfileAboutRows({
  DateTime? joinedAt,
  DateTime? friendsSince,
}) {
  final rows = <FriendProfileAboutRow>[];

  if (joinedAt != null) {
    rows.add(
      FriendProfileAboutRow(
        label: 'Joined Moment',
        value: _formatMonthYear(joinedAt),
      ),
    );
  }

  if (friendsSince != null) {
    rows.add(
      FriendProfileAboutRow(
        label: 'Connected',
        value: _formatMonthYear(friendsSince),
      ),
    );
  }

  return rows;
}

String _formatMonthYear(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = date.toLocal();
  return '${months[local.month - 1]} ${local.year}';
}
