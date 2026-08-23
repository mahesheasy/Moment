import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/prompts/presentation/cubit/prompt_cubit.dart';

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
          appBar: AppBar(title: Text('$emoji $name')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              Text('TODAY', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                summary.prompt.promptText,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                '${responses.length} ${responses.length == 1 ? 'moment' : 'moments'}',
                style: Theme.of(context).textTheme.titleMedium,
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
                MomentButton(
                  label: 'Respond with a moment',
                  onPressed: isSaving
                      ? null
                      : () => context.push(
                          AppRoutes.cameraForPrompt(
                            circleId: circleId,
                            promptId: summary.prompt.id,
                          ),
                        ),
                ),
              const SizedBox(height: AppSpacing.lg),
              MomentButton(
                label: 'Save as Memory',
                variant: MomentButtonVariant.secondary,
                isLoading: isSaving,
                onPressed: isSaving || responses.isEmpty
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
