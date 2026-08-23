import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/dark_page_chrome.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/memories/domain/entities/memory.dart';
import 'package:moment/features/memories/domain/entities/memory_theme.dart';
import 'package:moment/features/memories/presentation/cubit/memory_cubit.dart';
import 'package:moment/features/memories/presentation/widgets/memory_form_widgets.dart';

class MemoryEditPage extends StatefulWidget {
  const MemoryEditPage({required this.memoryId, super.key});

  final String memoryId;

  @override
  State<MemoryEditPage> createState() => _MemoryEditPageState();
}

class _MemoryEditPageState extends State<MemoryEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _captionController;
  MemoryTheme _theme = MemoryTheme.minimal;
  DateTime? _memoryDate;
  String? _coverMomentId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _bindDetail(MemoryDetail detail) {
    final summary = detail.summary;
    if (_titleController.text.isEmpty) {
      _titleController.text = summary.title;
      _captionController.text = summary.caption ?? '';
      _theme = summary.theme;
      _memoryDate = summary.memoryDate;
      _coverMomentId = summary.coverMomentId;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _memoryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.violet,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _memoryDate = picked);
  }

  Future<void> _pickCover(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    await context.read<MemoryEditCubit>().uploadCover(
      bytes,
      file.mimeType ?? 'image/jpeg',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MemoryEditCubit>(param1: widget.memoryId)..load(),
      child: BlocConsumer<MemoryEditCubit, MemoryEditState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.status == MemoryEditStatus.loading ||
              state.status == MemoryEditStatus.initial) {
            return MomentScaffold(
              appBar: MomentAppBar(
                title: 'Edit memory',
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => context.pop(),
                ),
              ),
              body: Center(child: MomentLoading()),
            );
          }

          if (state.detail == null) {
            return MomentScaffold(
              appBar: MomentAppBar(
                title: 'Edit memory',
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => context.pop(),
                ),
              ),
              body: MomentErrorState(
                message: state.errorMessage ?? 'Could not load memory.',
                onAction: () => context.read<MemoryEditCubit>().load(),
              ),
            );
          }

          final detail = state.detail!;
          _bindDetail(detail);
          final catalog = state.catalog;
          final isSaving = state.status == MemoryEditStatus.saving;

          return MomentScaffold(
            appBar: MomentAppBar(
              title: 'Edit memory',
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => context.pop(),
              ),
            ),
            bottomNavigationBar: ClipRect(
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
                  child: MomentButton(
                    label: 'Save changes',
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            final saved = await context
                                .read<MemoryEditCubit>()
                                .save(
                                  UpdateMemoryInput(
                                    memoryId: widget.memoryId,
                                    title: _titleController.text,
                                    caption: _captionController.text,
                                    theme: _theme,
                                    memoryDate: _memoryDate,
                                    coverMomentId: _coverMomentId,
                                  ),
                                );
                            if (saved && context.mounted) context.pop(true);
                          },
                  ),
                ),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.md,
                AppSpacing.xxl,
                120,
              ),
              children: [
                Text(
                  'Update title, theme, and cover for this memory.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl),
                MemoryFormSection(
                  title: 'DETAILS',
                  child: MemoryFormPanel(
                    child: Column(
                      children: [
                        MemoryFormField(
                          controller: _titleController,
                          label: 'Title',
                          hint: 'Memory title',
                        ),
                        SizedBox(height: AppSpacing.lg),
                        MemoryFormField(
                          controller: _captionController,
                          label: 'Caption',
                          hint: 'A short note about this memory',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl),
                MemoryFormSection(
                  title: 'DATE',
                  subtitle: 'Optional — when did this happen?',
                  child: MemoryFormPanel(
                    child: MemoryFormDateRow(
                      date: _memoryDate,
                      onTap: _pickDate,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl),
                MemoryFormSection(
                  title: 'THEME',
                  subtitle: 'Choose how this memory looks.',
                  child: MemoryFormPanel(
                    child: MemoryThemePicker(
                      themes: catalog?.themes ?? MemoryTheme.values,
                      selected: _theme,
                      isPremium: catalog?.isPremium ?? false,
                      onSelected: (theme) => setState(() => _theme = theme),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl),
                const DarkPageTitle('COVER'),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Pick a moment photo or upload your own.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryDark,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                MemoryFormPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Material(
                        color: AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: InkWell(
                          onTap: () => _pickCover(context),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.violet.withValues(
                                      alpha: 0.14,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.upload_outlined,
                                    size: 18,
                                    color: AppColors.violet,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    'Upload custom cover',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textTertiaryDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (detail.items.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          'FROM MOMENTS',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textTertiaryDark,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        for (var i = 0; i < detail.items.length; i++) ...[
                          if (i > 0) SizedBox(height: AppSpacing.sm),
                          _CoverMomentTile(
                            imageUrl: detail.items[i].moment.imageUrl,
                            name: detail.items[i].moment.sender.displayName,
                            selected:
                                _coverMomentId == detail.items[i].moment.id,
                            onTap: () => setState(
                              () => _coverMomentId = detail.items[i].moment.id,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CoverMomentTile extends StatelessWidget {
  const _CoverMomentTile({
    required this.name,
    required this.selected,
    required this.onTap,
    this.imageUrl,
  });

  final String? imageUrl;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.violet.withValues(alpha: 0.12)
          : AppColors.surfaceElevatedDark,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.violet : AppColors.borderDark,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: imageUrl == null
                      ? ColoredBox(color: AppColors.photoPlaceholderDark)
                      : Image.network(imageUrl!, fit: BoxFit.cover),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: selected ? AppColors.violet : AppColors.textTertiaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
