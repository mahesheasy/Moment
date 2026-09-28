import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/shared_pet/domain/entities/pet.dart';

class PetStats extends StatelessWidget {
  const PetStats({
    required this.pet,
    super.key,
  });

  final SharedPet pet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                pet.petName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              'Lv. ${pet.level}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pet.xpProgressFraction.clamp(0, 1),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'XP ${pet.xp} / ${SharedPet.xpPerLevel}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _StatRing(label: 'Hunger', value: pet.hunger)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _StatRing(label: 'Energy', value: pet.energy)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _StatRing(label: 'Happy', value: pet.happiness)),
          ],
        ),
      ],
    );
  }
}

class _StatRing extends StatelessWidget {
  const _StatRing({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          width: 52,
          child: CircularProgressIndicator(
            value: value / 100,
            strokeWidth: 5,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text('$value%', style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
