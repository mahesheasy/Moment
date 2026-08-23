import 'package:moment/core/result/result.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

abstract class FriendsRepository {
  Future<Result<List<FriendSummary>>> getFriends();

  Future<Result<List<FriendRequest>>> getIncomingRequests();

  Future<Result<List<FriendRequest>>> getOutgoingRequests();

  Future<Result<List<UserSearchResult>>> searchByUsername(String query);

  Future<Result<List<SuggestedFriend>>> getSuggestedFriends();

  Future<Result<UserProfile>> getFriendProfile(String userId);

  Future<Result<FriendRelationship>> getRelationship(String userId);

  Future<Result<String?>> getPendingRequestId(String userId);

  Future<Result<void>> sendFriendRequest(String receiverId);

  Future<Result<void>> acceptFriendRequest(String requestId);

  Future<Result<void>> rejectFriendRequest(String requestId);

  Future<Result<void>> cancelFriendRequest(String requestId);

  Future<Result<void>> removeFriend(String friendId);

  Future<Result<void>> blockUser(String userId);

  Future<Result<void>> unblockUser(String userId);

  Future<Result<List<BlockedUser>>> getBlockedUsers();

  Future<Result<void>> reportUser({
    required String userId,
    required String reason,
    String? details,
  });
}
