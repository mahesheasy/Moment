import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/friends/data/datasources/friends_remote_data_source.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  FriendsRepositoryImpl(this._remote, this._userIdProvider);

  final FriendsRemoteDataSource _remote;
  final String? Function() _userIdProvider;

  String? get _userId => _userIdProvider();

  @override
  Future<Result<List<FriendSummary>>> getFriends() async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getFriends(userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<FriendRequest>>> getIncomingRequests() async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getIncomingRequests(userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<FriendRequest>>> getOutgoingRequests() async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getOutgoingRequests(userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<UserSearchResult>>> searchByUsername(String query) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      final profiles = await _remote.searchProfiles(userId, query);
      final blockedIds = {
        for (final blocked in await _remote.getBlockedUsers(userId))
          blocked.profile.id,
      };

      final results = <UserSearchResult>[];
      for (final profile in profiles) {
        if (blockedIds.contains(profile.id)) continue;
        if (await _remote.hasBlocked(profile.id, userId)) continue;

        final relationship = await _resolveRelationship(userId, profile.id);
        final pending = await _remote.findPendingRequest(userId, profile.id);
        final mutualCount = await _remote.getMutualFriendCount(userId, profile.id);

        results.add(
          UserSearchResult(
            profile: profile,
            relationship: relationship,
            pendingRequestId: pending?.id,
            mutualFriendCount: mutualCount,
          ),
        );
      }
      results.sort(
        (a, b) => b.mutualFriendCount.compareTo(a.mutualFriendCount),
      );
      return Success(results);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<SuggestedFriend>>> getSuggestedFriends() async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      final rows = await _remote.getSuggestedFriends(userId);
      final suggestions = <SuggestedFriend>[];
      for (final row in rows) {
        final relationship = await _resolveRelationship(userId, row.profile.id);
        if (relationship == FriendRelationship.friends ||
            relationship == FriendRelationship.blocked ||
            relationship == FriendRelationship.blockedBy) {
          continue;
        }
        final pending = await _remote.findPendingRequest(userId, row.profile.id);
        suggestions.add(
          SuggestedFriend(
            profile: row.profile,
            mutualFriendCount: row.mutualCount,
            relationship: relationship,
            pendingRequestId: pending?.id,
          ),
        );
      }
      return Success(suggestions);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<UserProfile>> getFriendProfile(String userId) async {
    if (_userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getProfile(userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<int>> getMutualFriendCount(String userId) async {
    final currentUserId = _userId;
    if (currentUserId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(
        await _remote.getMutualFriendCount(currentUserId, userId),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<DateTime?>> getFriendshipSince(String friendId) async {
    final currentUserId = _userId;
    if (currentUserId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(
        await _remote.getFriendshipSince(currentUserId, friendId),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<String?>> getPendingRequestId(String userId) async {
    final currentUserId = _userId;
    if (currentUserId == null) return const Failed(AuthenticationFailure());

    try {
      final pending = await _remote.findPendingRequest(currentUserId, userId);
      return Success(pending?.id);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<FriendRelationship>> getRelationship(String userId) async {
    final currentUserId = _userId;
    if (currentUserId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _resolveRelationship(currentUserId, userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> sendFriendRequest(String receiverId) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());
    if (userId == receiverId) {
      return const Failed(
        ValidationFailure(message: 'You cannot add yourself.'),
      );
    }

    try {
      if (await _remote.areFriends(userId, receiverId)) {
        return const Failed(
          ValidationFailure(message: 'You are already friends.'),
        );
      }
      await _remote.sendFriendRequest(senderId: userId, receiverId: receiverId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> acceptFriendRequest(String requestId) async {
    if (_userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.acceptFriendRequest(requestId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> rejectFriendRequest(String requestId) async {
    if (_userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.rejectFriendRequest(requestId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> cancelFriendRequest(String requestId) async {
    if (_userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.cancelFriendRequest(requestId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> removeFriend(String friendId) async {
    if (_userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.removeFriend(friendId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> blockUser(String userId) async {
    final currentUserId = _userId;
    if (currentUserId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.blockUser(blockerId: currentUserId, blockedId: userId);
      await _remote.removeFriend(userId);
      final pending = await _remote.findPendingRequest(currentUserId, userId);
      if (pending != null && pending.isPending) {
        if (pending.sender.id == currentUserId) {
          await _remote.cancelFriendRequest(pending.id);
        } else {
          await _remote.rejectFriendRequest(pending.id);
        }
      }
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> unblockUser(String userId) async {
    final currentUserId = _userId;
    if (currentUserId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.unblockUser(blockerId: currentUserId, blockedId: userId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<BlockedUser>>> getBlockedUsers() async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getBlockedUsers(userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> reportUser({
    required String userId,
    required String reason,
    String? details,
  }) async {
    final reporterId = _userId;
    if (reporterId == null) return const Failed(AuthenticationFailure());

    final trimmedReason = reason.trim();
    if (trimmedReason.length < 3) {
      return const Failed(
        ValidationFailure(message: 'Please choose a report reason.'),
      );
    }

    try {
      await _remote.reportUser(
        reporterId: reporterId,
        reportedId: userId,
        reason: trimmedReason,
        details: details?.trim(),
      );
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  Future<FriendRelationship> _resolveRelationship(
    String currentUserId,
    String otherId,
  ) async {
    if (await _remote.hasBlocked(currentUserId, otherId)) {
      return FriendRelationship.blocked;
    }
    if (await _remote.hasBlocked(otherId, currentUserId)) {
      return FriendRelationship.blockedBy;
    }
    if (await _remote.areFriends(currentUserId, otherId)) {
      return FriendRelationship.friends;
    }

    final pending = await _remote.findPendingRequest(currentUserId, otherId);
    if (pending != null && pending.isPending) {
      return pending.sender.id == currentUserId
          ? FriendRelationship.requestSent
          : FriendRelationship.requestReceived;
    }

    return FriendRelationship.none;
  }
}
