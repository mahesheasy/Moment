import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/shared_pet/domain/entities/pet.dart';
import 'package:moment/features/shared_pet/engine/pet_animation_controller.dart';
import 'package:moment/features/shared_pet/engine/pet_behavior_controller.dart';
import 'package:moment/features/shared_pet/engine/pet_movement_controller.dart';
import 'package:moment/features/shared_pet/presentation/cubit/pet_cubit.dart';
import 'package:moment/features/shared_pet/presentation/cubit/pet_state.dart';
import 'package:moment/features/shared_pet/presentation/widgets/pet_3d_view.dart';
import 'package:moment/features/shared_pet/presentation/widgets/pet_action_bar.dart';
import 'package:moment/features/shared_pet/presentation/widgets/pet_room.dart';
import 'package:moment/features/shared_pet/presentation/widgets/pet_stats.dart';
import 'package:moment/features/shared_pet/presentation/widgets/pet_status.dart';

class SharedPetScreen extends StatefulWidget {
  const SharedPetScreen({required this.friendUserId, super.key});

  final String friendUserId;

  @override
  State<SharedPetScreen> createState() => _SharedPetScreenState();
}

class _SharedPetScreenState extends State<SharedPetScreen> {
  late final Flutter3DController _flutter3d;
  late final PetMovementController _movement;
  late final PetAnimationController _animation;
  PetBehaviorController? _behavior;
  int? _lastLevel;

  @override
  void initState() {
    super.initState();
    _flutter3d = Flutter3DController();
    _movement = PetMovementController();
    _animation = PetAnimationController(_flutter3d);
  }

  @override
  void dispose() {
    _behavior?.dispose();
    super.dispose();
  }

  Future<void> _runAction(BuildContext context, PetActionType action) async {
    await _behavior?.runUserActionSequence(action);
    if (!context.mounted) return;
    await context.read<PetCubit>().performAction(action);
  }

  void _ensureBehavior(SharedPet pet) {
    _behavior ??= PetBehaviorController(
      animation: _animation,
      movement: _movement,
    );
    _behavior!.attachPet(pet);
    _behavior!.start();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = PetCubit(sl(), sl(), friendUserId: widget.friendUserId);
        cubit.startIntegrationListener();
        cubit.load();
        return cubit;
      },
      child: BlocConsumer<PetCubit, PetState>(
        listener: (context, state) async {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
          final pet = state.pet;
          if (pet == null) return;

          if (_lastLevel != null && pet.level > _lastLevel!) {
            await _behavior?.celebrateLevelUp();
          }
          _lastLevel = pet.level;
        },
        builder: (context, state) {
          if (state.status == PetStatus.loading ||
              state.status == PetStatus.initial) {
            return Scaffold(
              appBar: AppBar(title: const Text('Our Pet')),
              body: const Center(child: MomentLoading()),
            );
          }

          if (state.status == PetStatus.failure && state.pet == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Our Pet')),
              body: MomentErrorState(
                message: state.errorMessage ?? 'Could not load pet.',
                actionLabel: 'Retry',
                onAction: () => context.read<PetCubit>().load(),
              ),
            );
          }

          final pet = state.pet;
          if (pet == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Our Pet')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Start a shared pet with your connection. '
                        'Care for it together and watch it grow.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: () => context.push(
                          AppRoutes.sharedPetCreate(widget.friendUserId),
                        ),
                        child: const Text('Create our pet'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          _ensureBehavior(pet);

          return Scaffold(
            appBar: AppBar(title: const Text('Our Pet')),
            body: Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const PetRoom(),
                      Pet3DView(
                        pet: pet,
                        movement: _movement,
                        flutter3dController: _flutter3d,
                        animationController: _animation,
                        onAssetMissing: () =>
                            context.read<PetCubit>().onModelAssetMissing(),
                        onAssetLoaded: () =>
                            context.read<PetCubit>().onModelAssetLoaded(),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: PetStatusChip(mood: pet.mood),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      PetStats(pet: pet),
                      const SizedBox(height: AppSpacing.md),
                      PetActionBar(
                        isBusy: state.status == PetStatus.acting,
                        isSleeping: pet.mood == PetMood.sleeping,
                        onFeed: () => _runAction(
                          context,
                          PetActionType.feed,
                        ),
                        onPlay: () => _runAction(
                          context,
                          PetActionType.play,
                        ),
                        onPet: () => _runAction(
                          context,
                          PetActionType.pet,
                        ),
                        onSleep: () => _runAction(
                          context,
                          pet.mood == PetMood.sleeping
                              ? PetActionType.wake
                              : PetActionType.sleep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
