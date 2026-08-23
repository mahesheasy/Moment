import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/moment_controls.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/features/settings/presentation/cubit/report_problem_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class ReportProblemPage extends StatelessWidget {
  const ReportProblemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportProblemCubit>(),
      child: const _ReportProblemView(),
    );
  }
}

class _ReportProblemView extends StatefulWidget {
  const _ReportProblemView();

  @override
  State<_ReportProblemView> createState() => _ReportProblemViewState();
}

class _ReportProblemViewState extends State<_ReportProblemView> {
  static const _categories = [
    'Bug',
    'Account issue',
    'Payments',
    'Feature request',
    'Other',
  ];

  var _category = _categories.first;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await context.read<ReportProblemCubit>().submit(
      category: _category,
      description: _descriptionController.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. We\'ll look into it.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportProblemCubit, ReportProblemState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;

        return MomentScaffold(
          appBar: MomentAppBar(
            title: 'Report a problem',
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(AppIcons.back, size: 18),
              onPressed: isSubmitting ? null : () => context.pop(),
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
                'Tell us what went wrong',
                style: SettingsType.title(AppColors.textPrimaryDark)
                    .copyWith(fontSize: 17, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Include as much detail as you can so we can help faster.',
                style: SettingsType.caption(AppColors.textTertiaryDark)
                    .copyWith(fontWeight: FontWeight.w400, fontSize: 11),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel(text: 'Category'),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.borderDark.withValues(alpha: 0.8),
                  ),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _categories.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: AppSpacing.lg,
                          endIndent: AppSpacing.lg,
                          color: AppColors.borderDark.withValues(alpha: 0.6),
                        ),
                      _CategoryRow(
                        label: _categories[i],
                        selected: _category == _categories[i],
                        enabled: !isSubmitting,
                        onTap: () => setState(() => _category = _categories[i]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel(text: 'Description'),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _descriptionController,
                enabled: !isSubmitting,
                maxLines: 5,
                style: SettingsType.body(AppColors.textPrimaryDark)
                    .copyWith(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'What happened? What were you trying to do?',
                  hintStyle: SettingsType.caption(AppColors.textTertiaryDark)
                      .copyWith(fontWeight: FontWeight.w400, fontSize: 11),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.borderDark.withValues(alpha: 0.8),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.borderDark.withValues(alpha: 0.8),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.violet.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              MomentButton(
                label: 'Submit report',
                isLoading: isSubmitting,
                onPressed: isSubmitting ? null : _submit,
              ),
            ],
          ),
        );
      },
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 11,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: SettingsType.body(
                  enabled
                      ? AppColors.textPrimaryDark
                      : AppColors.textTertiaryDark,
                ).copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            MomentRadioIndicator(
              selected: selected,
              activeColor: enabled ? AppColors.violet : AppColors.textTertiaryDark,
            ),
          ],
        ),
      ),
    );
  }
}
