import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';

enum CirclesStatus { initial, loading, loaded, creating, failure }

class CirclesState extends Equatable {
  const CirclesState({
    this.status = CirclesStatus.initial,
    this.circles = const [],
    this.friends = const [],
    this.activityByCircleId = const {},
    this.membersByCircleId = const {},
    this.errorMessage,
  });

  final CirclesStatus status;
  final List<Circle> circles;
  final List<FriendSummary> friends;
  final Map<String, CircleActivitySummary> activityByCircleId;
  final Map<String, List<CircleMember>> membersByCircleId;
  final String? errorMessage;

  int get totalPeople =>
      circles.fold<int>(0, (sum, circle) => sum + circle.memberCount);

  CirclesState copyWith({
    CirclesStatus? status,
    List<Circle>? circles,
    List<FriendSummary>? friends,
    Map<String, CircleActivitySummary>? activityByCircleId,
    Map<String, List<CircleMember>>? membersByCircleId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CirclesState(
      status: status ?? this.status,
      circles: circles ?? this.circles,
      friends: friends ?? this.friends,
      activityByCircleId: activityByCircleId ?? this.activityByCircleId,
      membersByCircleId: membersByCircleId ?? this.membersByCircleId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    circles,
    friends,
    activityByCircleId,
    membersByCircleId,
    errorMessage,
  ];
}

class CirclesCubit extends Cubit<CirclesState> {
  CirclesCubit(this._circles, this._friends) : super(const CirclesState());

  final CircleRepository _circles;
  final FriendsRepository _friends;

  Future<void> load() async {
    emit(state.copyWith(status: CirclesStatus.loading, clearError: true));

    final circlesResult = await _circles.getMyCircles();
    final friendsResult = await _friends.getFriends();

    switch (circlesResult) {
      case Success(:final value):
        final friends = switch (friendsResult) {
          Success(:final value) => value,
          Failed() => const <FriendSummary>[],
        };
        final summariesResult = await _circles.getCircleActivitySummaries(
          value.map((circle) => circle.id).toList(),
        );
        final membersResult = await _circles.getMembersForCircles(
          value.map((circle) => circle.id).toList(),
        );
        final summaries = switch (summariesResult) {
          Success(:final value) => value,
          Failed() => const <String, CircleActivitySummary>{},
        };
        final members = switch (membersResult) {
          Success(:final value) => value,
          Failed() => const <String, List<CircleMember>>{},
        };
        emit(
          state.copyWith(
            status: CirclesStatus.loaded,
            circles: value,
            friends: friends,
            activityByCircleId: summaries,
            membersByCircleId: members,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CirclesStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<Circle?> createCircle(CreateCircleInput input) async {
    emit(state.copyWith(status: CirclesStatus.creating, clearError: true));
    final result = await _circles.createCircle(input);

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: CirclesStatus.loaded,
            circles: [value, ...state.circles],
          ),
        );
        return value;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CirclesStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return null;
    }
  }
}
