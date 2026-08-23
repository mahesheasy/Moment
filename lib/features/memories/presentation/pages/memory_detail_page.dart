import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_avatar.dart';
import 'package:moment/core/widgets/moment_chip.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/memories/domain/entities/memory.dart';
import 'package:moment/features/memories/domain/entities/memory_theme.dart';
import 'package:moment/features/memories/presentation/cubit/memory_cubit.dart';
import 'package:moment/features/memories/presentation/widgets/memory_cover_hero.dart';

class MemoryDetailPage extends StatelessWidget {
  const MemoryDetailPage({required this.memoryId, super.key});

  final String memoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MemoryDetailCubit>(param1: memoryId)..load(),
      child: _MemoryDetailView(memoryId: memoryId),
    );
  }
}

class _MemoryDetailView extends StatelessWidget {
  const _MemoryDetailView({required this.memoryId});

  final String memoryId;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await MomentDialog.confirm(
      context,
      title: 'Delete memory?',
      message: 'This removes the saved chapter for everyone.',
      confirmLabel: 'Delete',
    );

    if (confirmed != true || !context.mounted) return;
    final deleted = await context.read<MemoryDetailCubit>().deleteMemory();
    if (deleted && context.mounted) {
      context.pop();
    }
  }

  Future<void> _addChapter(BuildContext context) async {
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _AddChapterDialog(),
    );
    if (title == null || title.trim().isEmpty || !context.mounted) return;
    await context.read<MemoryDetailCubit>().addChapter(title);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MemoryDetailCubit, MemoryDetailState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.savedMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.savedMessage!)));
        }
      },
      builder: (context, state) {
        if (state.status == MemoryDetailStatus.loading &&
            state.detail == null) {
          return MomentScaffold(
            appBar: MomentAppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(child: MomentLoading()),
          );
        }
        if (state.status == MemoryDetailStatus.failure &&
            state.detail == null) {
          return MomentScaffold(
            appBar: MomentAppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => context.pop(),
              ),
            ),
            body: MomentErrorState(
              message: state.errorMessage ?? 'Could not load memory.',
              actionLabel: 'Retry',
              onAction: () => context.read<MemoryDetailCubit>().load(),
            ),
          );
        }

        final detail = state.detail;
        if (detail == null) {
          return MomentScaffold(
            body: Center(child: MomentLoading()),
          );
        }

        final summary = detail.summary;
        final themeStyle = MemoryThemeStyle.forTheme(summary.theme);
        final isDeleting = state.status == MemoryDetailStatus.deleting;

        return MomentScaffold(
          extendBody: true,
          appBar: MomentAppBar(
            transparent: true,
            leading: _OverlayIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: () => context.pop(),
            ),
            actions: [
              if (detail.isOwner) ...[
                _OverlayIconButton(
                  icon: Icons.edit_outlined,
                  onPressed: () async {
                    final updated = await context.push<bool>(
                      AppRoutes.memoryEdit(memoryId),
                    );
                    if (updated == true && context.mounted) {
                      await context.read<MemoryDetailCubit>().load();
                    }
                  },
                ),
                _OverlayIconButton(
                  icon: Icons.library_add_outlined,
                  onPressed: () => _addChapter(context),
                ),
              ],
              if (detail.isOwner)
                _OverlayIconButton(
                  icon: Icons.delete_outline_rounded,
                  onPressed: isDeleting ? null : () => _confirmDelete(context),
                ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              MemoryCoverHero(
                memoryId: memoryId,
                imageUrl: summary.coverImageUrl,
                aspectRatio: 4 / 5,
              ),
              Transform.translate(
                offset: const Offset(0, -AppSpacing.xxl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MemoryDarkPanel(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            children: [
                              MomentBadge(label: summary.memoryType.label),
                              SizedBox(height: AppSpacing.md),
                              Text(
                                summary.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              if (summary.caption != null &&
                                  summary.caption!.isNotEmpty) ...[
                                SizedBox(height: AppSpacing.sm),
                                Text(
                                  summary.caption!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondaryDark,
                                      ),
                                ),
                              ],
                              if (summary.memoryDateLabel != null) ...[
                                SizedBox(height: AppSpacing.sm),
                                Text(
                                  summary.memoryDateLabel!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textTertiaryDark,
                                      ),
                                ),
                              ] else if (summary.dateRangeLabel != null) ...[
                                SizedBox(height: AppSpacing.sm),
                                Text(
                                  summary.dateRangeLabel!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textTertiaryDark,
                                      ),
                                ),
                              ],
                              SizedBox(height: AppSpacing.lg),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  _StatChip(
                                    label:
                                        '${summary.momentCount} ${summary.momentCount == 1 ? 'moment' : 'moments'}',
                                  ),
                                  _StatChip(
                                    label: '${summary.participantCount} people',
                                  ),
                                  _StatChip(label: '${summary.dayCount} days'),
                                  _StatChip(
                                    label: summary.theme.label,
                                    accent: themeStyle.titleColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxl),
                      if (detail.chapters.isNotEmpty)
                        ...detail.chapters.map(
                          (chapter) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xxl,
                            ),
                            child: _ChapterSection(
                              detail: detail,
                              chapter: chapter,
                            ),
                          ),
                        ),
                      if (detail.itemsForChapter(null).isNotEmpty) ...[
                        _SectionTitle(
                          detail.chapters.isEmpty ? 'Timeline' : 'More moments',
                        ),
                        SizedBox(height: AppSpacing.lg),
                        ...detail
                            .itemsForChapter(null)
                            .map((item) => _TimelineItem(item: item)),
                      ],
                      if (detail.participants.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.lg),
                        _SectionTitle('Participants'),
                        SizedBox(height: AppSpacing.lg),
                        MemoryDarkPanel(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final profile in detail.participants)
                                  Chip(
                                    backgroundColor:
                                        AppColors.surfaceElevatedDark,
                                    side: BorderSide.none,
                                    avatar: MomentAvatar(
                                      name: profile.displayName,
                                      imageUrl: profile.avatarUrl,
                                      size: 24,
                                    ),
                                    label: Text(
                                      profile.displayName,
                                      style: TextStyle(
                                        color: AppColors.textSecondaryDark,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: detail.isOwner ? 120 : AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: detail.isOwner
              ? ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.md,
                        AppSpacing.xxl,
                        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark.withValues(alpha: 0.92),
                        border: Border(
                          top: BorderSide(color: AppColors.borderDark),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: isDeleting
                              ? null
                              : () => _confirmDelete(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6B6B),
                            side: BorderSide(color: Color(0x66FF6B6B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: isDeleting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFF6B6B),
                                  ),
                                )
                              : Text('Delete memory'),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _AddChapterDialog extends StatefulWidget {
  const _AddChapterDialog();

  @override
  State<_AddChapterDialog> createState() => _AddChapterDialogState();
}

class _AddChapterDialogState extends State<_AddChapterDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Text('New chapter'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(labelText: 'Chapter title'),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text('Add'),
        ),
      ],
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, this.accent});

  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (accent ?? AppColors.surfaceElevatedDark).withValues(
          alpha: accent == null ? 1 : 0.18,
        ),
        borderRadius: BorderRadius.circular(14),
        border: accent != null
            ? Border.all(color: accent!.withValues(alpha: 0.35))
            : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: accent ?? AppColors.textSecondaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChapterSection extends StatelessWidget {
  const _ChapterSection({required this.detail, required this.chapter});

  final MemoryDetail detail;
  final MemoryChapter chapter;

  @override
  Widget build(BuildContext context) {
    final items = detail.itemsForChapter(chapter.id);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(chapter.title),
        if (chapter.caption != null) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            chapter.caption!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
        SizedBox(height: AppSpacing.lg),
        ...items.map((item) => _TimelineItem(item: item)),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.item});

  final MemoryTimelineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: MemoryDarkPanel(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MomentAvatar(
                name: item.moment.sender.displayName,
                imageUrl: item.moment.sender.avatarUrl,
                size: 36,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.moment.sender.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: () =>
                          context.push(AppRoutes.moment(item.moment.id)),
                      child: ClipRRect(
                        borderRadius: AppRadius.lgAll,
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: item.moment.imageUrl == null
                              ? ColoredBox(
                                  color: AppColors.photoPlaceholderDark,
                                )
                              : Image.network(
                                  item.moment.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    if (item.moment.caption != null) ...[
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        item.moment.caption!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
