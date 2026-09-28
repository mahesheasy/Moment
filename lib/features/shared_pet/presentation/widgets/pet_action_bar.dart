import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_spacing.dart';
class PetActionBar extends StatelessWidget {
  const PetActionBar({
    required this.onFeed,
    required this.onPlay,
    required this.onPet,
    required this.onSleep,
    required this.isBusy,
    required this.isSleeping,
    super.key,
  });

  final VoidCallback onFeed;
  final VoidCallback onPlay;
  final VoidCallback onPet;
  final VoidCallback onSleep;
  final bool isBusy;
  final bool isSleeping;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: Icons.restaurant,
            label: 'Feed',
            onTap: isBusy || isSleeping ? null : onFeed,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionChip(
            icon: Icons.sports_soccer,
            label: 'Play',
            onTap: isBusy || isSleeping ? null : onPlay,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionChip(
            icon: Icons.favorite,
            label: 'Pet',
            onTap: isBusy || isSleeping ? null : onPet,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionChip(
            icon: isSleeping ? Icons.wb_sunny_outlined : Icons.bedtime,
            label: isSleeping ? 'Wake' : 'Sleep',
            onTap: isBusy ? null : onSleep,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
