import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_breakpoints.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_component_sizes.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/dark_page_chrome.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'package:moment/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileCubit>()..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final maxWidth = AppBreakpoints.contentMaxWidth(context);
    final padding = AppBreakpoints.pagePadding(context);

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state.status == ProfileStatus.loading ||
            state.status == ProfileStatus.initial) {
          return const _ProfileLoadingView();
        }

        if (state.status == ProfileStatus.failure && state.profile == null) {
          return MomentScaffold(
            body: MomentErrorState(
              message: state.errorMessage ?? 'Could not load profile.',
              onAction: () => context.read<ProfileCubit>().load(),
            ),
          );
        }

        final profile = state.profile!;

        return ColoredBox(
          color: AppColors.backgroundDark,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ListView(
                  padding: padding.copyWith(
                    top: AppSpacing.lg,
                    bottom: 120,
                  ),
                  children: [
                    _ProfilePageHeader(
                      onSettings: () => context.push(AppRoutes.settings),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    _ProfileHero(
                      profile: profile,
                      stats: state.stats,
                      onEdit: () async {
                        await context.push(AppRoutes.profileEdit);
                        if (context.mounted) {
                          await context.read<ProfileCubit>().load();
                        }
                      },
                      onAvatarTap: () async {
                        await context.push(AppRoutes.profileEdit);
                        if (context.mounted) {
                          await context.read<ProfileCubit>().load();
                        }
                      },
                      onPeopleTap: () => context.push(AppRoutes.friends),
                      onCirclesTap: () => context.go(AppRoutes.circles),
                      onMemoriesTap: () => context.go(AppRoutes.memories),
                    ),
                    SizedBox(height: AppSpacing.xxl),
                    const _ProfileSectionLabel('Account'),
                    SizedBox(height: AppSpacing.md),
                    _ProfilePanel(
                      children: [
                        _ProfileMenuRow(
                          icon: AppIcons.profileFilled,
                          iconColor: const Color(0xFFFF6B8A),
                          iconBackground: const Color(0x33FF6B8A),
                          title: 'Edit profile',
                          subtitle: 'Photo, name, and bio',
                          onTap: () async {
                            await context.push(AppRoutes.profileEdit);
                            if (context.mounted) {
                              await context.read<ProfileCubit>().load();
                            }
                          },
                        ),
                        const _ProfileDivider(),
                        _ProfileMenuRow(
                          icon: AppIcons.circlesFilled,
                          iconColor: const Color(0xFFFF9A5C),
                          iconBackground: const Color(0x33FF9A5C),
                          title: 'Friends',
                          subtitle: 'Your connections and requests',
                          onTap: () => context.push(AppRoutes.friends),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xxl),
                    const _ProfileSectionLabel('Personalize'),
                    SizedBox(height: AppSpacing.md),
                    _ProfilePanel(
                      children: [
                        _ProfileMenuRow(
                          icon: Icons.widgets_outlined,
                          iconColor: const Color(0xFFC4A1FF),
                          iconBackground: const Color(0x33C4A1FF),
                          title: 'Home widget',
                          subtitle: 'Privacy, person, and theme',
                          onTap: () => context.push(AppRoutes.widgetCustomize),
                        ),
                        const _ProfileDivider(),
                        _ProfileMenuRow(
                          icon: Icons.auto_awesome_rounded,
                          iconColor: const Color(0xFFFF6B8A),
                          iconBackground: const Color(0x33FF6B8A),
                          title: 'Moment+',
                          subtitle: 'Premium themes and widget modes',
                          badge: const _NewBadge(),
                          onTap: () => context.push(AppRoutes.premium),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundDark,
      child: SafeArea(
        child: MomentShimmer(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: const [
              MomentShimmerBone(height: 18, width: 72, radius: 6),
              SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MomentShimmerBone(height: 76, width: 76, shape: BoxShape.circle),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MomentShimmerBone(height: 14, width: 100, radius: 6),
                        SizedBox(height: 6),
                        MomentShimmerBone(height: 10, width: 64, radius: 5),
                        SizedBox(height: 12),
                        MomentShimmerBone(height: 28, width: double.infinity, radius: 6),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              MomentShimmerBone(height: 10, width: 220, radius: 5),
              SizedBox(height: AppSpacing.xxl),
              MomentShimmerBone(height: 10, width: 56, radius: 5),
              SizedBox(height: AppSpacing.md),
              MomentShimmerBone(height: 108, width: double.infinity, radius: 14),
              SizedBox(height: AppSpacing.xxl),
              MomentShimmerBone(height: 10, width: 72, radius: 5),
              SizedBox(height: AppSpacing.md),
              MomentShimmerBone(height: 108, width: double.infinity, radius: 14),
              SizedBox(height: AppSpacing.xxl),
              MomentShimmerBone(height: 10, width: 48, radius: 5),
              SizedBox(height: AppSpacing.md),
              MomentShimmerBone(height: 220, width: double.infinity, radius: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePageHeader extends StatelessWidget {
  const _ProfilePageHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Profile',
            style: SettingsType.title(AppColors.textPrimaryDark).copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
        ),
        IconButton(
          onPressed: onSettings,
          icon: Icon(Icons.settings_outlined, size: 22),
          color: AppColors.textTertiaryDark,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: SettingsType.caption(AppColors.textTertiaryDark).copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.stats,
    required this.onEdit,
    required this.onAvatarTap,
    required this.onPeopleTap,
    required this.onCirclesTap,
    required this.onMemoriesTap,
  });

  final UserProfile profile;
  final ProfileStats stats;
  final VoidCallback onEdit;
  final VoidCallback onAvatarTap;
  final VoidCallback onPeopleTap;
  final VoidCallback onCirclesTap;
  final VoidCallback onMemoriesTap;

  @override
  Widget build(BuildContext context) {
    final bio = profile.bio?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileAvatar(
              profile: profile,
              onTap: onAvatarTap,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          profile.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SettingsType.title(AppColors.textPrimaryDark)
                              .copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      _ProfileEditButton(onTap: onEdit),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    '@${profile.username}',
                    style: SettingsType.body(AppColors.textTertiaryDark),
                  ),
                  SizedBox(height: AppSpacing.md),
                  _ProfileStatsRow(
                    stats: stats,
                    onPeopleTap: onPeopleTap,
                    onCirclesTap: onCirclesTap,
                    onMemoriesTap: onMemoriesTap,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (bio != null && bio.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          Text(
            bio,
            style: SettingsType.body(AppColors.textSecondaryDark).copyWith(
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, required this.onTap});

  final UserProfile profile;
  final VoidCallback onTap;

  static const double _outerSize = 76;
  static const double _innerSize = 68;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _outerSize,
            height: _outerSize,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.bloomGradient,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundDark,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: MomentAvatar(
                  name: profile.displayName,
                  imageUrl: profile.avatarUrl,
                  size: _innerSize,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundDark, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 12,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditButton extends StatelessWidget {
  const _ProfileEditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedDark,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Icon(
            Icons.edit_outlined,
            size: 15,
            color: AppColors.textTertiaryDark,
          ),
        ),
      ),
    );
  }
}

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({
    required this.stats,
    required this.onPeopleTap,
    required this.onCirclesTap,
    required this.onMemoriesTap,
  });

  final ProfileStats stats;
  final VoidCallback onPeopleTap;
  final VoidCallback onCirclesTap;
  final VoidCallback onMemoriesTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProfileStatItem(
          value: '${stats.peopleCount}',
          label: 'People',
          onTap: onPeopleTap,
        ),
        _ProfileStatDivider(),
        _ProfileStatItem(
          value: '${stats.circlesCount}',
          label: 'Circles',
          onTap: onCirclesTap,
        ),
        _ProfileStatDivider(),
        _ProfileStatItem(
          value: '${stats.memoriesCount}',
          label: 'Memories',
          onTap: onMemoriesTap,
        ),
      ],
    );
  }
}

class _ProfileStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 1,
        height: 22,
        color: AppColors.borderDark,
      ),
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  const _ProfileStatItem({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: SettingsType.title(AppColors.textPrimaryDark).copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: SettingsType.caption(AppColors.textTertiaryDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFB8860B),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'NEW',
        style: SettingsType.caption(Colors.white).copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.iconColor,
    required this.iconBackground,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  final Color iconBackground;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SettingsType.title(AppColors.textPrimaryDark)
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (badge != null) badge!,
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: SettingsType.caption(AppColors.textTertiaryDark)
                          .copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              Icon(
                AppIcons.chevronRight,
                size: 16,
                color: AppColors.textTertiaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
      color: AppColors.borderDark,
    );
  }
}

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  Uint8List? _pendingAvatarBytes;
  String? _pendingAvatarMime;
  String? _currentAvatarUrl;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _pendingAvatarBytes = bytes;
      _pendingAvatarMime = file.mimeType ?? 'image/jpeg';
    });
  }

  Future<void> _showPhotoOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
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
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Profile photo',
                  style: SettingsType.title(AppColors.textPrimaryDark),
                ),
                SizedBox(height: AppSpacing.lg),
                _PhotoOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from gallery',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                SizedBox(height: AppSpacing.sm),
                _PhotoOption(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take a photo',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) await _pickPhoto(source);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileCubit>()..load(),
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.loaded && state.profile != null) {
            final profile = state.profile!;
            if (_displayNameController.text.isEmpty) {
              _displayNameController.text = profile.displayName;
              _usernameController.text = profile.username;
              _bioController.text = profile.bio ?? '';
              _currentAvatarUrl = profile.avatarUrl;
              _displayName = profile.displayName;
            }
          }
          if (state.status == ProfileStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final isSaving = state.status == ProfileStatus.saving;
          final bottom = MediaQuery.paddingOf(context).bottom;

          return MomentScaffold(
            appBar: MomentAppBar(
              title: 'Edit profile',
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                onPressed: () => context.pop(),
              ),
            ),
            bottomNavigationBar: Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + bottom),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderDark.withValues(alpha: 0.8),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppComponentSizes.buttonHeightLg,
                child: FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final saved = await context.read<ProfileCubit>().save(
                            ProfileUpdate(
                              displayName: _displayNameController.text,
                              username: _usernameController.text,
                              bio: _bioController.text,
                            ),
                            avatarBytes: _pendingAvatarBytes,
                            avatarMimeType: _pendingAvatarMime,
                          );
                          if (saved && context.mounted) context.pop();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor:
                        AppColors.violet.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.lgAll,
                    ),
                    textStyle: SettingsType.title(Colors.white),
                  ),
                  child: isSaving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Save changes'),
                ),
              ),
            ),
            body: state.status == ProfileStatus.loading
                ? const _ProfileLoadingView()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.md,
                      AppSpacing.xxl,
                      120,
                    ),
                    children: [
                      Text(
                        'Add your photo and update how friends see you.',
                        style: SettingsType.body(AppColors.textSecondaryDark),
                      ),
                      SizedBox(height: AppSpacing.xxl),
                      Center(
                        child: Column(
                          children: [
                            _ProfilePhotoPicker(
                              displayName: _displayName ?? 'You',
                              imageUrl: _currentAvatarUrl,
                              pendingBytes: _pendingAvatarBytes,
                              onTap: isSaving ? null : _showPhotoOptions,
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tap to add or change photo',
                              style: SettingsType.caption(
                                AppColors.textTertiaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxxl),
                      const DarkPageTitle('DETAILS'),
                      SizedBox(height: AppSpacing.lg),
                      _EditPanel(
                        children: [
                          _EditField(
                            controller: _displayNameController,
                            label: 'Display name',
                            hint: 'How friends see you',
                          ),
                          const _ProfileDivider(),
                          _EditField(
                            controller: _usernameController,
                            label: 'Username',
                            hint: 'Your unique handle',
                            prefix: '@',
                          ),
                          const _ProfileDivider(),
                          _EditField(
                            controller: _bioController,
                            label: 'Bio',
                            hint: 'A short line about you',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({
    required this.displayName,
    required this.imageUrl,
    required this.pendingBytes,
    this.onTap,
  });

  final String displayName;
  final String? imageUrl;
  final Uint8List? pendingBytes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderDark, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: pendingBytes != null
                ? Image.memory(pendingBytes!, fit: BoxFit.cover)
                : MomentAvatar(
                    name: displayName,
                    imageUrl: imageUrl,
                    size: 104,
                  ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.violet,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundDark, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  const _PhotoOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevatedDark,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.violet),
              SizedBox(width: AppSpacing.md),
              Text(label, style: SettingsType.body(AppColors.textPrimaryDark)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditPanel extends StatelessWidget {
  const _EditPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(children: children),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    required this.hint,
    this.prefix,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? prefix;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: SettingsType.caption(AppColors.textTertiaryDark).copyWith(
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: SettingsType.body(AppColors.textPrimaryDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: SettingsType.body(AppColors.textTertiaryDark),
              prefixText: prefix,
              prefixStyle: SettingsType.body(AppColors.violet),
              filled: true,
              fillColor: AppColors.surfaceElevatedDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
