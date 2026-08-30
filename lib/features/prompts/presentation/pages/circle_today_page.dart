import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/prompts/presentation/cubit/prompt_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class CircleTodayPage extends StatelessWidget {
  const CircleTodayPage({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CircleTodayCubit>(param1: circleId)..load(),
      child: _CircleTodayView(circleId: circleId),
    );
  }
}

class _CircleTodayView extends StatelessWidget {
  const _CircleTodayView({required this.circleId});

  final String circleId;

  Future<void> _saveAsMemory(
    BuildContext context,
    CircleTodayState state,
  ) async {
    if (state.summary == null || state.summary!.responses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add prompt responses before saving a memory.'),
        ),
      );
      return;
    }

    final controller = TextEditingController(
      text: '${state.circleName ?? 'Circle'} · Today',
    );

    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Save as Memory'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Title'),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (title == null || title.trim().isEmpty || !context.mounted) return;

    final memory = await context.read<CircleTodayCubit>().saveAsMemory(title);
    if (memory != null && context.mounted) {
      await context.push(AppRoutes.memory(memory.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CircleTodayCubit, CircleTodayState>(
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
        if (state.status == CircleTodayStatus.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Today')),
            body: const Center(child: MomentLoading()),
          );
        }
        if (state.status == CircleTodayStatus.failure ||
            state.summary == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Today')),
            body: MomentErrorState(
              message: state.errorMessage ?? 'Could not load today.',
              actionLabel: 'Retry',
              onAction: () => context.read<CircleTodayCubit>().load(),
            ),
          );
        }

        final summary = state.summary!;
        final responses = summary.responses;
        final emoji = state.circleEmoji ?? '✨';
        final name = state.circleName ?? 'Circle';
        final isSaving = state.status == CircleTodayStatus.saving;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundDark,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              '$emoji $name',
              style: SettingsType.title(Colors.white).copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              Text(
                'TODAY',
                style: SettingsType.caption(AppColors.textTertiaryDark).copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                summary.prompt.promptText,
                style: SettingsType.title(Colors.white).copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                '${responses.length} ${responses.length == 1 ? 'moment' : 'moments'}',
                style: SettingsType.body(AppColors.textSecondaryDark),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (responses.isEmpty)
                const MomentEmptyState(
                  message: 'No responses yet.\nBe the first to share.',
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 4 / 5,
                  ),
                  itemCount: responses.length,
                  itemBuilder: (context, index) {
                    final response = responses[index];
                    final imageUrl = response.moment.imageUrl;
                    return GestureDetector(
                      onTap: () =>
                          context.push(AppRoutes.moment(response.moment.id)),
                      child: ClipRRect(
                        borderRadius: AppRadius.lgAll,
                        child: imageUrl == null
                            ? ColoredBox(color: Theme.of(context).dividerColor)
                            : Image.network(imageUrl, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.xxxl),
              if (!state.hasResponded)
                _PromptActionButton(
                  label: 'Respond with a moment',
                  onTap: isSaving
                      ? null
                      : () => context.push(
                          AppRoutes.cameraForPrompt(
                            circleId: circleId,
                            promptId: summary.prompt.id,
                          ),
                        ),
                ),
              const SizedBox(height: AppSpacing.lg),
              _PromptActionButton(
                label: 'Save as Memory',
                secondary: true,
                isLoading: isSaving,
                onTap: isSaving || responses.isEmpty
                    ? null
                    : () => _saveAsMemory(context, state),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PromptActionButton extends StatelessWidget {
  const _PromptActionButton({
    required this.label,
    this.onTap,
    this.secondary = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool secondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (secondary) {
      return SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: isLoading ? null : onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondaryDark,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  label,
                  style: SettingsType.body(AppColors.textSecondaryDark).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: onTap == null && !isLoading
            ? null
            : AppColors.bloomGradient,
        color: onTap == null && !isLoading
            ? AppColors.surfaceElevatedDark
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      style: SettingsType.body(Colors.white).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
