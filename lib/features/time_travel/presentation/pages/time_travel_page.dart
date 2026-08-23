import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/moment_card.dart';
import 'package:moment/features/time_travel/domain/entities/time_travel_entry.dart';
import 'package:moment/features/time_travel/presentation/cubit/time_travel_cubit.dart';

class TimeTravelSection extends StatelessWidget {
  const TimeTravelSection({this.darkStyle = false, super.key});

  final bool darkStyle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TimeTravelCubit>()..load(),
      child: BlocBuilder<TimeTravelCubit, TimeTravelState>(
        builder: (context, state) {
          if (state.status == TimeTravelStatus.loading ||
              state.status == TimeTravelStatus.initial) {
            return const SizedBox.shrink();
          }
          if (state.entries.isEmpty) {
            return const SizedBox.shrink();
          }

          final entry = state.entries.first;

          if (darkStyle) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Material(
                color: AppColors.surfaceDark,
                borderRadius: AppRadius.xxlAll,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push(AppRoutes.timeTravel),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderDark),
                      borderRadius: AppRadius.xxlAll,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _TimeTravelEntryBody(
                      entry: entry,
                      compact: true,
                      darkStyle: true,
                      onRelive: () =>
                          context.push(AppRoutes.moment(entry.moment!.id)),
                    ),
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: MomentCard(
              onTap: () => context.push(AppRoutes.timeTravel),
              child: _TimeTravelEntryBody(
                entry: entry,
                compact: true,
                onRelive: () =>
                    context.push(AppRoutes.moment(entry.moment!.id)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TimeTravelPage extends StatelessWidget {
  const TimeTravelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TimeTravelCubit>()..load(),
      child: const _TimeTravelPageView(),
    );
  }
}

class _TimeTravelPageView extends StatelessWidget {
  const _TimeTravelPageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Time Travel')),
      body: BlocBuilder<TimeTravelCubit, TimeTravelState>(
        builder: (context, state) {
          if (state.status == TimeTravelStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (state.status == TimeTravelStatus.failure) {
            return Center(child: Text(state.errorMessage ?? 'Could not load.'));
          }
          if (state.entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  'No moments from this day in past years yet.\nKeep sharing — future you will thank you.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            itemCount: state.entries.length,
            separatorBuilder: (_, index) =>
                const SizedBox(height: AppSpacing.xxxl),
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              return _TimeTravelEntryBody(
                entry: entry,
                onRelive: () =>
                    context.push(AppRoutes.moment(entry.moment!.id)),
              );
            },
          );
        },
      ),
    );
  }
}

class _TimeTravelEntryBody extends StatelessWidget {
  const _TimeTravelEntryBody({
    required this.entry,
    required this.onRelive,
    this.compact = false,
    this.darkStyle = false,
  });

  final TimeTravelEntry entry;
  final VoidCallback onRelive;
  final bool compact;
  final bool darkStyle;

  @override
  Widget build(BuildContext context) {
    final moment = entry.moment!;
    final imageUrl = moment.imageUrl;
    final accentColor = darkStyle ? AppColors.violet : null;
    final titleColor = darkStyle ? Colors.white : null;
    final bodyColor = darkStyle ? AppColors.textSecondaryDark : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '✨ TIME TRAVEL',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: accentColor,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          entry.headline,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),
        ClipRRect(
          borderRadius: AppRadius.xlAll,
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: imageUrl == null
                ? ColoredBox(
                    color: darkStyle
                        ? AppColors.photoPlaceholderDark
                        : AppColors.photoPlaceholder,
                  )
                : Image.network(imageUrl, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          entry.formattedDate,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: bodyColor,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            moment.sender.displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: bodyColor,
            ),
          ),
        ],
        if (!compact) ...[
          const SizedBox(height: AppSpacing.xxl),
          MomentButton(label: 'Relive', expanded: false, onPressed: onRelive),
        ],
      ],
    );
  }
}
