import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/memories/domain/entities/memory.dart';
import 'package:moment/features/memories/domain/entities/memory_theme.dart';
import 'package:moment/features/memories/presentation/cubit/memory_cubit.dart';
import 'package:moment/features/memories/presentation/widgets/memory_form_widgets.dart';

class CreateMemorySheet extends StatefulWidget {
  const CreateMemorySheet({super.key});

  static Future<MemorySummary?> show(BuildContext context) {
    return showModalBottomSheet<MemorySummary?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BlocProvider(
        create: (_) => sl<CreateMemoryCubit>()..load(),
        child: const CreateMemorySheet(),
      ),
    );
  }

  @override
  State<CreateMemorySheet> createState() => _CreateMemorySheetState();
}

class _CreateMemorySheetState extends State<CreateMemorySheet> {
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  MemoryType _type = MemoryType.trip;
  MemoryTheme _theme = MemoryTheme.minimal;
  DateTime? _memoryDate;
  String? _circleId;

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.92;

    return BlocConsumer<CreateMemoryCubit, CreateMemoryState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        if (state.status == CreateMemoryStatus.loading ||
            state.status == CreateMemoryStatus.initial) {
          return SizedBox(
            height: sheetHeight,
            child: Center(child: MomentLoading()),
          );
        }

        final catalog = state.catalog;
        final isSaving = state.status == CreateMemoryStatus.saving;
        final types =
            catalog?.memoryTypes ??
            [
              MemoryType.trip,
              MemoryType.anniversary,
              MemoryType.birthday,
              MemoryType.circle,
              MemoryType.custom,
            ];

        return SizedBox(
          height: sheetHeight,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                  ),
                  children: [
                    MemoryFormSheetHeader(
                      title: 'New memory',
                      subtitle: 'Save a chapter from your moments.',
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    SizedBox(height: AppSpacing.xxxl),
                    MemoryFormSection(
                      title: 'TYPE',
                      subtitle: 'What kind of memory is this?',
                      child: MemoryFormPanel(
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: types.map((type) {
                            return MemoryFormChip(
                              label: type.label,
                              selected: _type == type,
                              onTap: () => setState(() {
                                _type = type;
                                if (type != MemoryType.circle) {
                                  _circleId = null;
                                }
                              }),
                            );
                          }).toList(),
                        ),
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
                              hint: 'Summer trip, Birthday 2026…',
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
                    if (_type == MemoryType.circle) ...[
                      SizedBox(height: AppSpacing.xxxl),
                      MemoryFormSection(
                        title: 'CIRCLE',
                        subtitle: 'Link this memory to a circle.',
                        child: MemoryFormPanel(
                          child: Column(
                            children: [
                              for (
                                var i = 0;
                                i < state.circles.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  SizedBox(height: AppSpacing.sm),
                                MemoryFormCircleTile(
                                  emoji: state.circles[i].displayEmoji,
                                  name: state.circles[i].name,
                                  subtitle: state.circles[i].type.label,
                                  selected: _circleId == state.circles[i].id,
                                  onTap: () => setState(
                                    () => _circleId = state.circles[i].id,
                                  ),
                                ),
                              ],
                              if (state.circles.isEmpty)
                                Text(
                                  'Create a circle first to link this memory.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textTertiaryDark,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                    SizedBox(height: 120),
                  ],
                ),
              ),
              MemoryFormStickyBar(
                label: 'Create memory',
                isLoading: isSaving,
                onPressed: isSaving
                    ? null
                    : () async {
                        final memory = await context
                            .read<CreateMemoryCubit>()
                            .create(
                              CreateAdvancedMemoryInput(
                                title: _titleController.text,
                                memoryType: _type,
                                caption: _captionController.text,
                                theme: _theme,
                                memoryDate: _memoryDate,
                                circleId: _circleId,
                              ),
                            );
                        if (context.mounted) {
                          Navigator.of(context).pop(memory);
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}
