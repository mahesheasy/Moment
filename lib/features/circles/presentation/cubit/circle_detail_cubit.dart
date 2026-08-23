import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';
import 'package:moment/features/moments/domain/repositories/moment_repository.dart';
import 'package:moment/features/moments/domain/repositories/social_repository.dart';

enum CircleDetailStatus { initial, loading, loaded, acting, failure }

class CircleDetailState extends Equatable {
  const CircleDetailState({
    this.status = CircleDetailStatus.initial,
    this.circle,
    this.members = const [],
    this.friends = const [],
    this.moments = const [],
    this.reactionsByMomentId = const {},
    this.avatarCacheKey = 0,
    this.errorMessage,
    this.actionMessage,
  });

  final CircleDetailStatus status;
  final Circle? circle;
  final List<CircleMember> members;
  final List<FriendSummary> friends;
  final List<Moment> moments;
  final Map<String, MomentReactionSummary> reactionsByMomentId;
  final int avatarCacheKey;
  final String? errorMessage;
  final String? actionMessage;

  CircleDetailState copyWith({
    CircleDetailStatus? status,
    Circle? circle,
    List<CircleMember>? members,
    List<FriendSummary>? friends,
    List<Moment>? moments,
    Map<String, MomentReactionSummary>? reactionsByMomentId,
    int? avatarCacheKey,
    String? errorMessage,
    String? actionMessage,
    bool clearError = false,
    bool clearAction = false,
  }) {
    return CircleDetailState(
      status: status ?? this.status,
      circle: circle ?? this.circle,
      members: members ?? this.members,
      friends: friends ?? this.friends,
      moments: moments ?? this.moments,
      reactionsByMomentId:
          reactionsByMomentId ?? this.reactionsByMomentId,
      avatarCacheKey: avatarCacheKey ?? this.avatarCacheKey,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      actionMessage: clearAction ? null : actionMessage ?? this.actionMessage,
    );
  }

  List<FriendSummary> get addableFriends {
    final memberIds = {for (final member in members) member.profile.id};
    return friends
        .where((friend) => !memberIds.contains(friend.profile.id))
        .toList();
  }

  @override
  List<Object?> get props => [
    status,
    circle,
    members,
    friends,
    moments,
    reactionsByMomentId,
    avatarCacheKey,
    errorMessage,
    actionMessage,
  ];

  Moment? get latestMoment => moments.isEmpty ? null : moments.first;
}

class CircleDetailCubit extends Cubit<CircleDetailState> {
  CircleDetailCubit(
    this._circles,
    this._friends,
    this._moments,
    this._social,
    this._circleId,
  ) : super(const CircleDetailState());

  final CircleRepository _circles;
  final FriendsRepository _friends;
  final MomentRepository _moments;
  final SocialRepository _social;
  final String _circleId;

  Future<void> load() async {
    emit(state.copyWith(status: CircleDetailStatus.loading, clearError: true));

    final circleResult = await _circles.getCircle(_circleId);
    final membersResult = await _circles.getCircleMembers(_circleId);
    final friendsResult = await _friends.getFriends();

    switch (circleResult) {
      case Success(:final value):
        final members = switch (membersResult) {
          Success(:final value) => value,
          Failed() => const <CircleMember>[],
        };
        final friends = switch (friendsResult) {
          Success(:final value) => value,
          Failed() => const <FriendSummary>[],
        };
        final moments = await _momentsForCircle(_circleId);
        emit(
          state.copyWith(
            status: CircleDetailStatus.loaded,
            circle: value,
            members: members,
            friends: friends,
            moments: moments,
            reactionsByMomentId: await _loadReactionsForMoments(moments),
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CircleDetailStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> addMember(String userId) async {
    if (state.members.length >= CircleLimits.maxMembers) {
      emit(
        state.copyWith(
          status: CircleDetailStatus.loaded,
          errorMessage:
              'A circle can have at most ${CircleLimits.maxMembers} members.',
        ),
      );
      return;
    }
    emit(state.copyWith(status: CircleDetailStatus.acting, clearError: true));
    final result = await _circles.addMember(
      circleId: _circleId,
      userId: userId,
    );

    switch (result) {
      case Success():
        await load();
        emit(
          state.copyWith(
            status: CircleDetailStatus.loaded,
            actionMessage: 'Member added.',
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CircleDetailStatus.loaded,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> removeMember(String userId) async {
    emit(state.copyWith(status: CircleDetailStatus.acting, clearError: true));
    final result = await _circles.removeMember(
      circleId: _circleId,
      userId: userId,
    );

    switch (result) {
      case Success():
        await load();
        emit(
          state.copyWith(
            status: CircleDetailStatus.loaded,
            actionMessage: 'Member removed.',
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CircleDetailStatus.loaded,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<bool> uploadCirclePhoto({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    emit(state.copyWith(status: CircleDetailStatus.acting, clearError: true));
    final result = await _circles.uploadCircleAvatar(
      circleId: _circleId,
      bytes: bytes,
      mimeType: mimeType,
    );

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: CircleDetailStatus.loaded,
            circle: value,
            avatarCacheKey: state.avatarCacheKey + 1,
            actionMessage: 'Circle photo updated.',
          ),
        );
        return true;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CircleDetailStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return false;
    }
  }

  Future<bool> leaveCircle() async {
    emit(state.copyWith(status: CircleDetailStatus.acting, clearError: true));
    final result = await _circles.leaveCircle(circleId: _circleId);

    switch (result) {
      case Success():
        return true;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CircleDetailStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return false;
    }
  }

  Future<bool> deleteCircle() async {
    emit(state.copyWith(status: CircleDetailStatus.acting, clearError: true));
    final result = await _circles.deleteCircle(circleId: _circleId);

    switch (result) {
      case Success():
        return true;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CircleDetailStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return false;
    }
  }

  Future<bool> renameCircle(String name) async {
    emit(state.copyWith(status: CircleDetailStatus.acting, clearError: true));
    final result = await _circles.updateCircleName(
      circleId: _circleId,
      name: name,
    );

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: CircleDetailStatus.loaded,
            circle: value,
            actionMessage: 'Circle renamed.',
          ),
        );
        return true;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CircleDetailStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return false;
    }
  }

  Future<void> reactToLatest(ReactionType type) async {
    final moment = state.latestMoment;
    if (moment == null) return;
    final result = await _social.react(momentId: moment.id, reaction: type);
    switch (result) {
      case Success():
        final summary = await _loadReaction(moment.id);
        if (summary != null) {
          emit(
            state.copyWith(
              actionMessage: 'Reacted',
              reactionsByMomentId: {
                ...state.reactionsByMomentId,
                moment.id: summary,
              },
            ),
          );
        } else {
          emit(state.copyWith(actionMessage: 'Reacted'));
        }
      case Failed(:final failure):
        emit(state.copyWith(errorMessage: failure.message));
    }
  }

  Future<void> pingLatest() async {
    final moment = state.latestMoment;
    if (moment == null) return;
    final result = await _social.sendPing(
      recipientId: moment.sender.id,
      momentId: moment.id,
    );
    switch (result) {
      case Success():
        emit(state.copyWith(actionMessage: 'Ping sent.'));
      case Failed(:final failure):
        emit(state.copyWith(errorMessage: failure.message));
    }
  }

  Future<List<Moment>> _momentsForCircle(String circleId) async {
    final result = await _moments.listMomentsSharedToCircle(circleId);
    return switch (result) {
      Success(:final value) => value,
      Failed() => const <Moment>[],
    };
  }

  Future<Map<String, MomentReactionSummary>> _loadReactionsForMoments(
    List<Moment> moments,
  ) async {
    final reactions = <String, MomentReactionSummary>{};
    await Future.wait(
      moments.map((moment) async {
        final summary = await _loadReaction(moment.id);
        if (summary != null) reactions[moment.id] = summary;
      }),
    );
    return reactions;
  }

  Future<MomentReactionSummary?> _loadReaction(String momentId) async {
    final result = await _social.getReactionSummary(momentId);
    return switch (result) {
      Success(:final value) => value,
      Failed() => null,
    };
  }
}
