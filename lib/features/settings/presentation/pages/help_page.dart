import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/features/settings/presentation/widgets/settings_group.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _topics = [
    _HelpTopic(
      question: 'How do I add friends?',
      answer:
          'Go to Profile → People, or open Friends from the home screen. Search by username and tap Add, or accept incoming requests.',
    ),
    _HelpTopic(
      question: 'How do moments work?',
      answer:
          'Capture a photo from the camera tab and send it to friends. They appear on the home feed and can be saved to Memories.',
    ),
    _HelpTopic(
      question: 'What is Moment+?',
      answer:'Moment+ unlocks premium widgets, themes, unlimited memories, Time Travel+, and more customization.',
      route: AppRoutes.premium,
      routeLabel: 'View Moment+',
    ),
    _HelpTopic(
      question: 'How do I block someone?',
      answer:'Open Friends, tap a friend, then choose Block from the menu. You can manage blocked users in Settings → Blocked users.',
      route: AppRoutes.blockedUsers,
      routeLabel: 'Blocked users',
    ),
    _HelpTopic(
      question: 'How do widgets work?',
      answer:  'Add the Moment widget to your home screen from Widget settings. Your latest unseen moment appears there in real time.',
      route: AppRoutes.widgetCustomize,
      routeLabel: 'Widget settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MomentScaffold(
      appBar: MomentAppBar(
        title: 'Help',
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        children: [
          Text(
            'How can we help?',
            style: SettingsType.title(AppColors.textPrimaryDark)
                .copyWith(fontSize: 17, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4),
          Text(
            'Find answers or reach out to our team.',
            style: SettingsType.caption(AppColors.textTertiaryDark)
                .copyWith(fontWeight: FontWeight.w400, fontSize: 11),
          ),
          SizedBox(height: AppSpacing.xl),
          SettingsSection(
            title: 'Quick help',
            children: [
              _QuickActionRow(
                icon: Icons.bug_report_outlined,
                title: 'Report a problem',
                subtitle: 'Something not working? Tell us.',
                onTap: () => context.push(AppRoutes.reportProblem),
              ),
              _QuickActionRow(
                icon: Icons.notifications_outlined,
                title: 'Notification settings',
                subtitle: 'Manage what you get notified about.',
                onTap: () => context.push(AppRoutes.notificationSettings),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xxl),
          const _SectionLabel(text: 'Frequently asked'),
          SizedBox(height: AppSpacing.sm),
          _FaqList(topics: _topics),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: SettingsType.caption(AppColors.textTertiaryDark)
            .copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.4),
      ),
    );
  }
}

class _HelpTopic {
  const _HelpTopic({
    required this.question,
    required this.answer,
    this.route,
    this.routeLabel,
  });

  final String question;
  final String answer;
  final String? route;
  final String? routeLabel;
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accentSoftDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.violet, size: 16),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SettingsType.body(AppColors.textPrimaryDark)
                        .copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  Text(
                    subtitle,
                    style: SettingsType.caption(AppColors.textTertiaryDark)
                        .copyWith(fontWeight: FontWeight.w400, fontSize: 10),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.chevronRight,
              size: 14,
              color: AppColors.textTertiaryDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqList extends StatefulWidget {
  const _FaqList({required this.topics});

  final List<_HelpTopic> topics;

  @override
  State<_FaqList> createState() => _FaqListState();
}

class _FaqListState extends State<_FaqList> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < widget.topics.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
                color: AppColors.borderDark.withValues(alpha: 0.6),
              ),
            _FaqTile(
              topic: widget.topics[i],
              expanded: _expandedIndex == i,
              onTap: () => setState(() {
                _expandedIndex = _expandedIndex == i ? null : i;
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.topic,
    required this.expanded,
    required this.onTap,
  });

  final _HelpTopic topic;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          12,
          AppSpacing.lg,
          12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    topic.question,
                    style: SettingsType.body(AppColors.textPrimaryDark)
                        .copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textTertiaryDark,
                  size: 18,
                ),
              ],
            ),
            if (expanded) ...[
              SizedBox(height: 8),
              Text(
                topic.answer,
                style: SettingsType.caption(AppColors.textSecondaryDark)
                    .copyWith(fontWeight: FontWeight.w400, fontSize: 11, height: 1.45),
              ),
              if (topic.route != null) ...[
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.push(topic.route!),
                  child: Text(
                    topic.routeLabel ?? 'Learn more',
                    style: SettingsType.caption(AppColors.violet)
                        .copyWith(fontWeight: FontWeight.w500, fontSize: 10),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
