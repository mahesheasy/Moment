import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/utils/relative_time.dart';
import 'package:moment/core/widgets/dark_page_chrome.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';
import 'package:moment/features/moments/presentation/cubit/pings_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class HomePingsSection extends StatelessWidget {
  const HomePingsSection({super.key});

  static const _types = <({String emoji, String label})>[
    (emoji: '👋', label: 'Hey'),
    (emoji: '❤️', label: 'Love'),
    (emoji: '😂', label: 'Haha'),
    (emoji: '🔥', label: 'Lit'),
    (emoji: '📍', label: 'Here'),
  ];

  Future<void> _send(
    BuildContext context, {
    required String emoji,
    required String label,
    String? recipientId,
  }) async {
    final cubit = context.read<PingsCubit>();
    final friends = cubit.state.friends;
    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add a friend first, then ping them.')),
      );
      return;
    }

    var targetId = recipientId;
    if (targetId == null) {
      final recipient = await _pickFriend(
        context,
        friends,
        emoji: emoji,
        label: label,
      );
      if (recipient == null || !context.mounted) return;
      targetId = recipient.profile.id;
    }

    await cubit.sendPing(recipientId: targetId, emoji: emoji, label: label);
  }

  Future<FriendSummary?> _pickFriend(
    BuildContext context,
    List<FriendSummary> friends, {
    String? emoji,
    String? label,
  }) {
    return showModalBottomSheet<FriendSummary>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderDark,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                DarkPageTitle(
                  emoji != null ? 'SEND $label $emoji' : 'PING WHO',
                ),
                if (emoji != null) ...[
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Choose who gets this ping',
                    style: SettingsType.caption(AppColors.textTertiaryDark),
                  ),
                ],
                SizedBox(height: AppSpacing.lg),
                for (final friend in friends)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Navigator.pop(sheetContext, friend),
                    leading: MomentAvatar(
                      name: friend.profile.displayName,
                      imageUrl: friend.profile.avatarUrl,
                      size: 40,
                    ),
                    title: Text(
                      friend.profile.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openThread(BuildContext context, PingThread thread) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderDark,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                MomentAvatar(
                  name: thread.person.displayName,
                  imageUrl: thread.person.avatarUrl,
                  size: 56,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  thread.person.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final ping in thread.pings.take(4))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: ping.sentByMe
                              ? AppColors.violet.withValues(alpha: 0.18)
                              : AppColors.surfaceElevatedDark,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '${ping.sentByMe ? 'You' : thread.person.displayName}  ${ping.emoji}',
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final type in _types)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _EmojiOrb(
                            emoji: type.emoji,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _send(
                                context,
                                emoji: type.emoji,
                                label: type.label,
                                recipientId: thread.person.id,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PingsCubit, PingsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.actionMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
        }
      },
      builder: (context, state) {
        if (state.status == PingsStatus.loading ||
            state.status == PingsStatus.initial) {
          return const _PingsShimmer();
        }

        final threads = groupPingsByPerson(state.recent);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'PINGS',
              actionLabel: 'See all',
              onAction: state.friends.isEmpty
                  ? null
                  : () => _pickFriend(context, state.friends),
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _types.length,
                separatorBuilder: (_, _) => SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final type = _types[index];
                  return _ComposerChip(
                    emoji: type.emoji,
                    label: type.label,
                    onTap: () => _send(
                      context,
                      emoji: type.emoji,
                      label: type.label,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            _SectionHeader(
              title: 'RECENT',
              actionLabel: 'View all',
              onAction: threads.isEmpty ? null : () {},
            ),
            SizedBox(height: AppSpacing.lg),
            if (threads.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No pings yet. Send one above.',
                      style: SettingsType.body(AppColors.textTertiaryDark),
                    ),
                    if (state.friends.isEmpty) ...[
                      SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.friends),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.violet,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Add friends'),
                      ),
                    ],
                  ],
                ),
              )
            else
              Column(
                children: [
                  for (final thread in threads.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecentPingRow(
                        thread: thread,
                        onOpen: () => _openThread(context, thread),
                        onSayHi: () => _send(
                          context,
                          emoji: '👋',
                          label: 'Hey',
                          recipientId: thread.person.id,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: SettingsType.caption(AppColors.violet).copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
        Spacer(),
        if (onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: SettingsType.caption(AppColors.textTertiaryDark),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: AppColors.textTertiaryDark,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentPingRow extends StatelessWidget {
  const _RecentPingRow({
    required this.thread,
    required this.onOpen,
    required this.onSayHi,
  });

  final PingThread thread;
  final VoidCallback onOpen;
  final VoidCallback onSayHi;

  @override
  Widget build(BuildContext context) {
    final incoming = !thread.latest.sentByMe;

    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: incoming ? AppColors.bloomGradient : null,
                      border: incoming
                          ? null
                          : Border.all(color: AppColors.borderDark, width: 1.2),
                    ),
                    child: MomentAvatar(
                      name: thread.person.displayName,
                      imageUrl: thread.person.avatarUrl,
                      size: 40,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.backgroundDark,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          thread.latest.emoji,
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.person.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SettingsType.body(AppColors.textPrimaryDark)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 2),
                    Text(
                      thread.count > 1
                          ? '${thread.count} pings · ${relativeTimeAgo(thread.latest.createdAt)}'
                          : relativeTimeAgo(thread.latest.createdAt),
                      style: SettingsType.caption(AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onSayHi,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.violet,
                  side: BorderSide(
                    color: AppColors.violet.withValues(alpha: 0.45),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: SettingsType.caption(AppColors.violet).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: Text('Say Hi 👋'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerChip extends StatelessWidget {
  const _ComposerChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceDark,
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          SizedBox(height: 5),
          Text(
            label,
            style: SettingsType.caption(AppColors.textTertiaryDark).copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiOrb extends StatelessWidget {
  const _EmojiOrb({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevatedDark,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}

class _PingsShimmer extends StatelessWidget {
  const _PingsShimmer();

  @override
  Widget build(BuildContext context) {
    return const MomentShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MomentShimmerBone(width: 72, height: 14, radius: 7),
          SizedBox(height: AppSpacing.lg),
          MomentShimmerBone(height: 84, radius: 16),
          SizedBox(height: AppSpacing.xxl),
          MomentShimmerBone(width: 72, height: 14, radius: 7),
          SizedBox(height: AppSpacing.lg),
          MomentShimmerBone(height: 120, radius: 16),
        ],
      ),
    );
  }
}
