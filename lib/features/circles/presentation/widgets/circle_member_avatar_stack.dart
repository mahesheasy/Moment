import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_hero_tags.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class CircleMemberAvatarStack extends StatelessWidget {
  const CircleMemberAvatarStack({
    required this.circleId,
    required this.members,
    this.maxVisible = 3,
    this.size = 26,
    this.heroEnabled = false,
    super.key,
  });

  final String circleId;
  final List<CircleMember> members;
  final int maxVisible;
  final double size;
  final bool heroEnabled;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    final visible = members.take(maxVisible).toList();
    final overflow = members.length - visible.length;
    final slot = size * 0.68;
    final extra = overflow > 0 ? slot : 0.0;
    final width = size + (visible.length - 1) * slot + extra;

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * slot,
              child: _MemberAvatar(
                circleId: circleId,
                member: visible[i],
                size: size,
                heroEnabled: heroEnabled,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * slot,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceElevatedDark,
                  border: Border.all(color: AppColors.borderDark, width: 1.2),
                ),
                child: Text(
                  '+$overflow',
                  style: SettingsType.caption(AppColors.textSecondaryDark)
                      .copyWith(fontSize: 9, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.circleId,
    required this.member,
    required this.size,
    required this.heroEnabled,
  });

  final String circleId;
  final CircleMember member;
  final double size;
  final bool heroEnabled;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.backgroundDark, width: 1.5),
      ),
      child: MomentAvatar(
        name: member.profile.displayName,
        imageUrl: member.profile.avatarUrl,
        size: size - 2,
      ),
    );

    if (!heroEnabled) return avatar;

    return Hero(
      tag: MomentHeroTags.circleMember(circleId, member.profile.id),
      child: Material(
        color: Colors.transparent,
        child: avatar,
      ),
    );
  }
}
