import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/prompts/domain/entities/daily_prompt.dart';
import 'package:moment/features/prompts/presentation/cubit/prompt_cubit.dart';

class DailyPromptCard extends StatelessWidget {
  const DailyPromptCard({this.darkStyle = false, super.key});

  final bool darkStyle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PromptCubit>()..loadToday(),
      child: BlocBuilder<PromptCubit, PromptState>(
        builder: (context, state) {
          if (state.status == PromptStatus.loading ||
              state.status == PromptStatus.initial) {
            return darkStyle
                ? const _DailyPromptShimmer()
                : const SizedBox.shrink();
          }
          if (state.status == PromptStatus.failure || state.prompt == null) {
            return const SizedBox.shrink();
          }

          final prompt = state.prompt!;
          final backgroundColor =
              darkStyle ? AppColors.surfaceDark : AppColors.ink;
          final titleColor = darkStyle ? Colors.white : AppColors.cream;
          final mutedColor = darkStyle
              ? AppColors.textSecondaryDark
              : AppColors.cream.withValues(alpha: 0.72);
          final labelColor = darkStyle
              ? AppColors.violet
              : AppColors.cream.withValues(alpha: 0.62);

          if (darkStyle) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              child: Material(
                color: AppColors.surfaceDark,
                borderRadius: AppRadius.xlAll,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openCirclePicker(context, prompt),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.accentSoftDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('✨', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share a moment of calm',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                prompt.promptText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textTertiaryDark,
                                      height: 1.35,
                                      fontSize: 12,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.bloomGradient,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  AppIcons.camera,
                                  size: 15,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Camera',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Material(
              color: backgroundColor,
              borderRadius: AppRadius.xlAll,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openCirclePicker(context, prompt),
                borderRadius: AppRadius.xlAll,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today’s prompt',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: labelColor,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        prompt.promptText,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: titleColor,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Text(
                            'Reply with a circle',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: mutedColor),
                          ),
                          const Spacer(),
                          Icon(
                            AppIcons.chevronRight,
                            size: 18,
                            color: mutedColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCirclePicker(
    BuildContext context,
    DailyPrompt prompt,
  ) async {
    final cubit = context.read<PromptCubit>();
    if (cubit.state.circles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a circle first to respond.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                'Respond with',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final circle in cubit.state.circles)
                ListTile(
                  leading: Text(
                    circle.displayEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(circle.name),
                  subtitle: Text(circle.type.label),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(
                      AppRoutes.cameraForPrompt(
                        circleId: circle.id,
                        promptId: prompt.id,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DailyPromptShimmer extends StatelessWidget {
  const _DailyPromptShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xxxl),
      child: SizedBox(height: 28),
    );
  }
}
