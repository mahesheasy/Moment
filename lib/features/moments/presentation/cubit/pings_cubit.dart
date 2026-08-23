import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';
import 'package:moment/features/moments/domain/repositories/social_repository.dart';

enum PingsStatus { initial, loading, loaded, sending, failure }

class PingsState extends Equatable {
  const PingsState({
    this.status = PingsStatus.initial,
    this.friends = const [],
    this.recent = const [],
    this.errorMessage,
    this.actionMessage,
  });

  final PingsStatus status;
  final List<FriendSummary> friends;
  final List<PingActivity> recent;
  final String? errorMessage;
  final String? actionMessage;

  PingsState copyWith({
    PingsStatus? status,
    List<FriendSummary>? friends,
    List<PingActivity>? recent,
    String? errorMessage,
    String? actionMessage,
    bool clearMessages = false,
  }) {
    return PingsState(
      status: status ?? this.status,
      friends: friends ?? this.friends,
      recent: recent ?? this.recent,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      actionMessage: clearMessages ? null : actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    friends,
    recent,
    errorMessage,
    actionMessage,
  ];
}

class PingsCubit extends Cubit<PingsState> {
  PingsCubit(this._social, this._friends) : super(const PingsState());

  final SocialRepository _social;
  final FriendsRepository _friends;

  Future<void> load() async {
    emit(state.copyWith(status: PingsStatus.loading, clearMessages: true));
    final friendsResult = await _friends.getFriends();
    final pingsResult = await _social.listRecentPings();

    final friends = switch (friendsResult) {
      Success(:final value) => value,
      Failed() => const <FriendSummary>[],
    };
    switch (pingsResult) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: PingsStatus.loaded,
            friends: friends,
            recent: value,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: PingsStatus.failure,
            friends: friends,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> sendPing({
    required String recipientId,
    required String emoji,
    required String label,
  }) async {
    emit(state.copyWith(status: PingsStatus.sending, clearMessages: true));
    final result = await _social.sendPing(
      recipientId: recipientId,
      emoji: emoji,
    );
    switch (result) {
      case Success():
        await load();
        emit(
          state.copyWith(
            status: PingsStatus.loaded,
            actionMessage: '$label sent $emoji',
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: PingsStatus.loaded,
            errorMessage: failure.message,
          ),
        );
    }
  }
}
