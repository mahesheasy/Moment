import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

enum FriendsStatus { initial, loading, loaded, acting, failure }

class FriendsState extends Equatable {
  const FriendsState({
    this.status = FriendsStatus.initial,
    this.friends = const [],
    this.incoming = const [],
    this.outgoing = const [],
    this.suggestions = const [],
    this.searchResults = const [],
    this.searchQuery = '',
    this.actingOn,
    this.errorMessage,
    this.actionMessage,
  });

  final FriendsStatus status;
  final List<FriendSummary> friends;
  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;
  final List<SuggestedFriend> suggestions;
  final List<UserSearchResult> searchResults;
  final String searchQuery;
  final String? actingOn;
  final String? errorMessage;
  final String? actionMessage;

  int get pendingCount => incoming.length;

  bool isActingOn(String key) => actingOn == key;

  FriendsState copyWith({
    FriendsStatus? status,
    List<FriendSummary>? friends,
    List<FriendRequest>? incoming,
    List<FriendRequest>? outgoing,
    List<SuggestedFriend>? suggestions,
    List<UserSearchResult>? searchResults,
    String? searchQuery,
    String? actingOn,
    String? errorMessage,
    String? actionMessage,
    bool clearError = false,
    bool clearActing = false,
    bool clearActionMessage = false,
  }) {
    return FriendsState(
      status: status ?? this.status,
      friends: friends ?? this.friends,
      incoming: incoming ?? this.incoming,
      outgoing: outgoing ?? this.outgoing,
      suggestions: suggestions ?? this.suggestions,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      actingOn: clearActing ? null : actingOn ?? this.actingOn,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      actionMessage: clearActionMessage
          ? null
          : actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    friends,
    incoming,
    outgoing,
    suggestions,
    searchResults,
    searchQuery,
    actingOn,
    errorMessage,
    actionMessage,
  ];
}

class FriendsCubit extends Cubit<FriendsState> {
  FriendsCubit(this._repository) : super(const FriendsState());

  final FriendsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: FriendsStatus.loading, clearError: true));
    await _refreshAll(showLoading: false);
  }

  void clearMessages() {
    if (state.errorMessage == null && state.actionMessage == null) return;
    emit(state.copyWith(clearError: true, clearActionMessage: true));
  }

  Future<void> search(String query) async {
    emit(
      state.copyWith(
        searchQuery: query,
        searchResults: query.trim().length < 2 ? [] : state.searchResults,
        clearError: true,
      ),
    );

    if (query.trim().length < 2) return;

    final result = await _repository.searchByUsername(query);
    result.when(
      success: (results) => emit(
        state.copyWith(
          status: FriendsStatus.loaded,
          searchResults: results,
          clearError: true,
        ),
      ),
      failure: (failure) => emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
    );
  }

  Future<void> sendRequest(String receiverId) async {
    emit(
      state.copyWith(
        status: FriendsStatus.acting,
        actingOn: 'send:$receiverId',
        clearError: true,
        clearActionMessage: true,
      ),
    );
    final result = await _repository.sendFriendRequest(receiverId);
    switch (result) {
      case Success():
        await _refreshAll(showLoading: false);
        if (state.searchQuery.trim().length >= 2) {
          await search(state.searchQuery);
        }
        emit(state.copyWith(clearActing: true, clearError: true));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: FriendsStatus.loaded,
            clearActing: true,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> acceptRequest(String requestId) async {
    emit(
      state.copyWith(
        status: FriendsStatus.acting,
        actingOn: 'accept:$requestId',
        clearError: true,
        clearActionMessage: true,
      ),
    );
    final result = await _repository.acceptFriendRequest(requestId);
    switch (result) {
      case Success():
        await _refreshAll(showLoading: false);
        emit(state.copyWith(clearActing: true, clearError: true));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: FriendsStatus.loaded,
            clearActing: true,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> rejectRequest(String requestId) async {
    emit(
      state.copyWith(
        status: FriendsStatus.acting,
        actingOn: 'reject:$requestId',
        clearError: true,
        clearActionMessage: true,
      ),
    );
    final result = await _repository.rejectFriendRequest(requestId);
    switch (result) {
      case Success():
        await _refreshAll(showLoading: false);
        emit(state.copyWith(clearActing: true, clearError: true));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: FriendsStatus.loaded,
            clearActing: true,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> cancelRequest(String requestId) async {
    emit(
      state.copyWith(
        status: FriendsStatus.acting,
        actingOn: 'cancel:$requestId',
        clearError: true,
        clearActionMessage: true,
      ),
    );
    final result = await _repository.cancelFriendRequest(requestId);
    switch (result) {
      case Success():
        await _refreshAll(showLoading: false);
        if (state.searchQuery.trim().length >= 2) {
          await search(state.searchQuery);
        }
        emit(state.copyWith(clearActing: true, clearError: true));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: FriendsStatus.loaded,
            clearActing: true,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> removeFriend(String friendId) async {
    emit(
      state.copyWith(
        status: FriendsStatus.acting,
        actingOn: 'remove:$friendId',
        clearError: true,
        clearActionMessage: true,
      ),
    );
    final result = await _repository.removeFriend(friendId);
    switch (result) {
      case Success():
        await _refreshAll(showLoading: false);
        emit(state.copyWith(clearActing: true, clearError: true));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: FriendsStatus.loaded,
            clearActing: true,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> blockUser(String userId) async {
    emit(
      state.copyWith(
        status: FriendsStatus.acting,
        actingOn: 'block:$userId',
        clearError: true,
        clearActionMessage: true,
      ),
    );
    final result = await _repository.blockUser(userId);
    switch (result) {
      case Success():
        await _refreshAll(showLoading: false);
        emit(state.copyWith(clearActing: true, clearError: true));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: FriendsStatus.loaded,
            clearActing: true,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> reportUser(
    String userId,
    String reason, {
    String? details,
  }) async {
    emit(
      state.copyWith(
        status: FriendsStatus.acting,
        actingOn: 'report:$userId',
        clearError: true,
        clearActionMessage: true,
      ),
    );
    final result = await _repository.reportUser(
      userId: userId,
      reason: reason,
      details: details,
    );
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            status: FriendsStatus.loaded,
            clearActing: true,
            actionMessage: 'Report submitted.',
            clearError: true,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: FriendsStatus.loaded,
            clearActing: true,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> _refreshAll({required bool showLoading}) async {
    if (showLoading) {
      emit(state.copyWith(status: FriendsStatus.loading, clearError: true));
    }

    final friendsResult = await _repository.getFriends();
    final incomingResult = await _repository.getIncomingRequests();
    final outgoingResult = await _repository.getOutgoingRequests();
    final suggestionsResult = await _repository.getSuggestedFriends();

    Failure? failure;
    var friends = state.friends;
    var incoming = state.incoming;
    var outgoing = state.outgoing;
    var suggestions = state.suggestions;

    friendsResult.when(
      success: (value) => friends = value,
      failure: (f) => failure = f,
    );
    incomingResult.when(
      success: (value) => incoming = value,
      failure: (f) => failure ??= f,
    );
    outgoingResult.when(
      success: (value) => outgoing = value,
      failure: (f) => failure ??= f,
    );
    suggestionsResult.when(
      success: (value) => suggestions = value,
      failure: (_) => suggestions = const [],
    );

    if (failure != null) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: failure!.message,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: FriendsStatus.loaded,
        friends: friends,
        incoming: incoming,
        outgoing: outgoing,
        suggestions: suggestions,
        clearActing: true,
        clearError: true,
      ),
    );
  }
}

enum FriendProfileStatus { initial, loading, loaded, acting, failure }

class FriendProfileState extends Equatable {
  const FriendProfileState({
    this.status = FriendProfileStatus.initial,
    this.profile,
    this.relationship = FriendRelationship.none,
    this.pendingRequestId,
    this.errorMessage,
    this.actionMessage,
  });

  final FriendProfileStatus status;
  final UserProfile? profile;
  final FriendRelationship relationship;
  final String? pendingRequestId;
  final String? errorMessage;
  final String? actionMessage;

  FriendProfileState copyWith({
    FriendProfileStatus? status,
    UserProfile? profile,
    FriendRelationship? relationship,
    String? pendingRequestId,
    String? errorMessage,
    String? actionMessage,
    bool clearMessages = false,
  }) {
    return FriendProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      relationship: relationship ?? this.relationship,
      pendingRequestId: pendingRequestId ?? this.pendingRequestId,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      actionMessage: clearMessages ? null : actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    relationship,
    pendingRequestId,
    errorMessage,
    actionMessage,
  ];
}

class FriendProfileCubit extends Cubit<FriendProfileState> {
  FriendProfileCubit(this._repository, this._userId)
    : super(const FriendProfileState());

  final FriendsRepository _repository;
  final String _userId;

  Future<void> load() async {
    emit(
      state.copyWith(status: FriendProfileStatus.loading, clearMessages: true),
    );

    final profileResult = await _repository.getFriendProfile(_userId);
    switch (profileResult) {
      case Failed(:final failure):
        emit(
          FriendProfileState(
            status: FriendProfileStatus.failure,
            errorMessage: failure.message,
          ),
        );
        return;
      case Success(:final value):
        final profile = value;
        final relationshipResult = await _repository.getRelationship(_userId);
        switch (relationshipResult) {
          case Failed(:final failure):
            emit(
              FriendProfileState(
                status: FriendProfileStatus.failure,
                profile: profile,
                errorMessage: failure.message,
              ),
            );
          case Success(:final value):
            final relationship = value;
            String? pendingRequestId;
            if (relationship == FriendRelationship.requestSent ||
                relationship == FriendRelationship.requestReceived) {
              final pendingResult = await _repository.getPendingRequestId(
                _userId,
              );
              pendingRequestId = pendingResult.valueOrNull;
            }

            emit(
              FriendProfileState(
                status: FriendProfileStatus.loaded,
                profile: profile,
                relationship: relationship,
                pendingRequestId: pendingRequestId,
              ),
            );
        }
    }
  }

  Future<void> sendRequest() async {
    await _act(() => _repository.sendFriendRequest(_userId));
  }

  Future<void> acceptRequest(String requestId) async {
    await _act(() => _repository.acceptFriendRequest(requestId));
  }

  Future<void> rejectRequest(String requestId) async {
    await _act(() => _repository.rejectFriendRequest(requestId));
  }

  Future<void> cancelRequest(String requestId) async {
    await _act(() => _repository.cancelFriendRequest(requestId));
  }

  Future<void> removeFriend() async {
    await _act(() => _repository.removeFriend(_userId));
  }

  Future<void> blockUser() async {
    await _act(
      () => _repository.blockUser(_userId),
      successMessage: 'User blocked.',
    );
  }

  Future<void> reportUser(String reason, {String? details}) async {
    await _act(
      () => _repository.reportUser(
        userId: _userId,
        reason: reason,
        details: details,
      ),
      successMessage: 'Report submitted.',
    );
  }

  Future<void> _act(
    Future<Result<void>> Function() action, {
    String? successMessage,
  }) async {
    emit(
      state.copyWith(status: FriendProfileStatus.acting, clearMessages: true),
    );
    final result = await action();
    switch (result) {
      case Success():
        await load();
        emit(
          state.copyWith(actionMessage: successMessage, clearMessages: false),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: FriendProfileStatus.loaded,
            errorMessage: failure.message,
          ),
        );
    }
  }
}

class BlockedUsersCubit extends Cubit<BlockedUsersState> {
  BlockedUsersCubit(this._repository) : super(const BlockedUsersState());

  final FriendsRepository _repository;

  Future<void> load() async {
    emit(const BlockedUsersState.loading());
    final result = await _repository.getBlockedUsers();
    result.when(
      success: (users) => emit(
        BlockedUsersState(status: BlockedUsersStatus.loaded, users: users),
      ),
      failure: (failure) => emit(
        BlockedUsersState(
          status: BlockedUsersStatus.failure,
          errorMessage: failure.message,
        ),
      ),
    );
  }

  Future<void> unblock(String userId) async {
    final result = await _repository.unblockUser(userId);
    result.when(
      success: (_) => load(),
      failure: (failure) => emit(
        state.copyWith(
          status: BlockedUsersStatus.failure,
          errorMessage: failure.message,
        ),
      ),
    );
  }
}

enum BlockedUsersStatus { initial, loading, loaded, failure }

class BlockedUsersState extends Equatable {
  const BlockedUsersState({
    this.status = BlockedUsersStatus.initial,
    this.users = const [],
    this.errorMessage,
  });

  const BlockedUsersState.loading()
    : status = BlockedUsersStatus.loading,
      users = const [],
      errorMessage = null;

  final BlockedUsersStatus status;
  final List<BlockedUser> users;
  final String? errorMessage;

  BlockedUsersState copyWith({
    BlockedUsersStatus? status,
    List<BlockedUser>? users,
    String? errorMessage,
  }) {
    return BlockedUsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, users, errorMessage];
}
