import 'package:flutter/material.dart';
import 'package:moment/features/shared_pet/domain/entities/pet.dart';

class PetStatusChip extends StatelessWidget {
  const PetStatusChip({required this.mood, super.key});

  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (mood) {
      PetMood.happy => ('Happy', Colors.greenAccent),
      PetMood.hungry => ('Hungry', Colors.orangeAccent),
      PetMood.tired => ('Tired', Colors.blueGrey),
      PetMood.sad => ('Needs love', Colors.deepPurpleAccent),
      PetMood.excited => ('Excited', Colors.pinkAccent),
      PetMood.sleeping => ('Sleeping', Colors.indigoAccent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
