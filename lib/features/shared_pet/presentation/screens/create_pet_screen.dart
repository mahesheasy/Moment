import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/moment_scaffold.dart';
import 'package:moment/features/shared_pet/domain/entities/pet.dart';
import 'package:moment/features/shared_pet/presentation/cubit/pet_cubit.dart';
import 'package:moment/features/shared_pet/presentation/cubit/pet_state.dart';

class CreatePetScreen extends StatefulWidget {
  const CreatePetScreen({required this.friendUserId, super.key});

  final String friendUserId;

  @override
  State<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends State<CreatePetScreen> {
  int _step = 0;
  PetType _type = PetType.cat;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PetCubit(
        sl(),
        sl(),
        friendUserId: widget.friendUserId,
      ),
      child: BlocConsumer<PetCubit, PetState>(
        listener: (context, state) {
          if (state.pet != null && state.status == PetStatus.loaded) {
            context.pop(true);
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          return MomentScaffold(
            appBar: AppBar(title: const Text('Create your pet')),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_step == 0) ...[
                    Text(
                      'Choose your first pet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _PetTypeCard(
                      type: PetType.cat,
                      title: 'Cat',
                      subtitle: 'Playful · Curious · Cozy',
                      selected: _type == PetType.cat,
                      enabled: true,
                      onTap: () => setState(() => _type = PetType.cat),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PetTypeCard(
                      type: PetType.dog,
                      title: 'Dog',
                      subtitle: 'Coming soon',
                      selected: false,
                      enabled: false,
                      onTap: () {},
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PetTypeCard(
                      type: PetType.bunny,
                      title: 'Bunny',
                      subtitle: 'Coming soon',
                      selected: false,
                      enabled: false,
                      onTap: () {},
                    ),
                  ] else ...[
                    Text(
                      'Name your pet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Milo',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 32,
                    ),
                  ],
                  const Spacer(),
                  MomentButton(
                    label: _step == 0 ? 'Next' : 'Create pet',
                    isLoading: state.status == PetStatus.acting,
                    onPressed: () {
                      if (_step == 0) {
                        setState(() => _step = 1);
                        return;
                      }
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;
                      context.read<PetCubit>().createPet(
                            petType: _type,
                            petName: name,
                          );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PetTypeCard extends StatelessWidget {
  const _PetTypeCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PetType type;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: ListTile(
        onTap: enabled ? onTap : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        leading: const Icon(Icons.pets),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: selected ? const Icon(Icons.check_circle) : null,
      ),
    );
  }
}
