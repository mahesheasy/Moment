import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:moment/features/shared_pet/domain/entities/pet.dart';
import 'package:moment/features/shared_pet/engine/pet_animation_controller.dart';
import 'package:moment/features/shared_pet/engine/pet_behavior_state.dart';
import 'package:moment/features/shared_pet/engine/pet_decision_engine.dart';
import 'package:moment/features/shared_pet/engine/pet_movement_controller.dart';
import 'package:moment/features/shared_pet/engine/pet_room_layout.dart';

/// Local autonomous behavior — does not sync movement to Supabase.
class PetBehaviorController with WidgetsBindingObserver {
  PetBehaviorController({
    required PetAnimationController animation,
    required PetMovementController movement,
    PetDecisionEngine? decisionEngine,
  })  : _animation = animation,
        _movement = movement,
        _decision = decisionEngine ?? PetDecisionEngine();

  final PetAnimationController _animation;
  final PetMovementController _movement;
  final PetDecisionEngine _decision;

  PetBehaviorState _state = PetBehaviorState.idle;
  PetBehaviorState get state => _state;

  SharedPet? _pet;
  Timer? _tickTimer;
  bool _paused = false;
  bool _running = false;

  void attachPet(SharedPet pet) {
    _pet = pet;
    if (pet.mood == PetMood.sleeping) {
      _transition(PetBehaviorState.sleeping);
      _animation.playSleep();
      _movement.snapTo(PetRoomAnchor.bed);
    }
  }

  void start() {
    if (_running) return;
    _running = true;
    WidgetsBinding.instance.addObserver(this);
    _scheduleTick(const Duration(seconds: 4));
  }

  void stop() {
    _running = false;
    _tickTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  void dispose() {
    stop();
    _movement.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    if (_paused) {
      _tickTimer?.cancel();
    } else if (_running) {
      _scheduleTick(const Duration(milliseconds: 800));
    }
  }

  Future<void> runUserActionSequence(PetActionType action) async {
    if (_pet == null) return;
    _tickTimer?.cancel();
    switch (action) {
      case PetActionType.feed:
        await _walkAndAct(
          PetRoomAnchor.foodBowl,
          PetBehaviorState.eating,
          _animation.playEat,
        );
      case PetActionType.drink:
        await _walkAndAct(
          PetRoomAnchor.waterBowl,
          PetBehaviorState.drinking,
          _animation.playDrink,
        );
      case PetActionType.play:
        await _walkAndAct(
          PetRoomAnchor.toy,
          PetBehaviorState.playing,
          _animation.playPlay,
        );
      case PetActionType.sleep:
        await _walkAndAct(
          PetRoomAnchor.bed,
          PetBehaviorState.sleeping,
          _animation.playSleep,
        );
      case PetActionType.wake:
        _transition(PetBehaviorState.waking);
        _animation.playWake();
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        _transition(PetBehaviorState.idle);
        _animation.playIdle();
      case PetActionType.pet:
        _transition(PetBehaviorState.reacting);
        _animation.playHappy();
        await Future<void>.delayed(const Duration(milliseconds: 900));
        _transition(PetBehaviorState.idle);
        _animation.playIdle();
      default:
        break;
    }
    if (_running && !_paused) {
      _scheduleTick(const Duration(seconds: 3));
    }
  }

  Future<void> celebrateLevelUp() async {
    _tickTimer?.cancel();
    _transition(PetBehaviorState.celebrating);
    _animation.playCelebrate();
    await Future<void>.delayed(const Duration(milliseconds: 2000));
    _transition(PetBehaviorState.idle);
    _animation.playIdle();
    if (_running && !_paused) _scheduleTick(const Duration(seconds: 4));
  }

  void _scheduleTick(Duration delay) {
    _tickTimer?.cancel();
    _tickTimer = Timer(delay, () {
      if (!_running || _paused || _pet == null) return;
      unawaited(_autonomousTick());
    });
  }

  Future<void> _autonomousTick() async {
    final pet = _pet!;
    if (pet.mood == PetMood.sleeping) {
      _scheduleTick(const Duration(seconds: 6));
      return;
    }

    final intent = _decision.decide(pet);
    final anchor = _decision.anchorFor(intent);

    switch (intent) {
      case PetAutonomousIntent.goEat:
        await _walkAndAct(
          anchor,
          PetBehaviorState.eating,
          _animation.playEat,
          dwellMs: 1800,
        );
      case PetAutonomousIntent.goDrink:
        await _walkAndAct(
          anchor,
          PetBehaviorState.drinking,
          _animation.playDrink,
          dwellMs: 1400,
        );
      case PetAutonomousIntent.goSleep:
        await _walkAndAct(
          anchor,
          PetBehaviorState.sleeping,
          _animation.playSleep,
          dwellMs: 2500,
        );
      case PetAutonomousIntent.goPlay:
        await _walkAndAct(
          anchor,
          PetBehaviorState.playing,
          _animation.playPlay,
          dwellMs: 1600,
        );
      case PetAutonomousIntent.idleWander:
        await _walkTo(anchor);
        _transition(PetBehaviorState.idle);
        _animation.playIdle();
    }

    if (_running && !_paused) {
      _scheduleTick(Duration(seconds: 5 + (intent.index % 3)));
    }
  }

  Future<void> _walkAndAct(
    PetRoomAnchor anchor,
    PetBehaviorState actionState,
    void Function() playAnim, {
    int dwellMs = 1500,
  }) async {
    await _walkTo(anchor);
    _transition(actionState);
    playAnim();
    await Future<void>.delayed(Duration(milliseconds: dwellMs));
    if (actionState == PetBehaviorState.sleeping) {
      return;
    }
    _transition(PetBehaviorState.idle);
    _animation.playIdle();
  }

  Future<void> _walkTo(PetRoomAnchor anchor) async {
    _transition(PetBehaviorState.walking);
    _animation.playWalk();
    _animation.setCameraOrbitForFacing(_movement.facingRadians);
    await _movement.moveTo(anchor);
    _animation.setCameraOrbitForFacing(_movement.facingRadians);
  }

  void _transition(PetBehaviorState next) {
    if (!_state.canTransitionTo(next) && _state != next) {
      return;
    }
    _state = next;
  }
}
