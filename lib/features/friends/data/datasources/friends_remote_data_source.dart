import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/errors/postgrest_mapper.dart';
import 'package:moment/features/friends/data/models/friend_models.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/profile/data/models/profile_model.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsRemoteDataSource {
  FriendsRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _requestSelect =
      'id, status, created_at, sender:sender_id(*), receiver:receiver_id(*)';

  Future<List<UserProfile>> discoverProfiles(
    String userId, {
    int limit = 12,
  }) async {
    final friendRows = await _client
        .from('friendships')
        .select('friend_id')
        .eq('user_id', userId);
    final exclude = <String>{userId};
    for (final row in friendRows as List) {
      exclude.add(row['friend_id'] as String);
    }

    final data = await _client
        .from('profiles')
        .select()
        .not('id', 'in', exclude.toList())
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map(
          (row) => ProfileModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toEntity(),
        )
        .toList();
  }

  Future<List<({UserProfile profile, int mutualCount})>> getSuggestedFriends(
    String userId, {
    int limit = 15,
  }) async {
    try {
      final data = await _client.rpc<List<dynamic>>(
        'suggest_friends',
        params: {'p_limit': limit},
      );

      return (data)
          .map((row) {
            final map = Map<String, dynamic>.from(row as Map);
            final profile = UserProfile(
              id: map['profile_id'] as String,
              username: map['username'] as String,
              displayName: map['display_name'] as String,
              avatarUrl: map['avatar_url'] as String?,
              bio: map['bio'] as String?,
            );
            final mutualCount = (map['mutual_count'] as num?)?.toInt() ?? 0;
            return (profile: profile, mutualCount: mutualCount);
          })
          .where((row) => row.mutualCount > 0)
          .toList();
    } on Object {
      // RPC not deployed yet — fall through to discover list.
    }

    final discover = await discoverProfiles(userId, limit: limit);
    return [
      for (final profile in discover) (profile: profile, mutualCount: 0),
    ];
  }

  Future<int> getMutualFriendCount(String userId, String otherId) async {
    try {
      final data = await _client.rpc<num>(
        'mutual_friend_count',
        params: {'other_id': otherId},
      );
      return data.toInt();
    } on Object {
      return _mutualFriendCountLocal(userId, otherId);
    }
  }

  Future<int> _mutualFriendCountLocal(String userId, String otherId) async {
    final mine = await _client
        .from('friendships')
        .select('friend_id')
        .eq('user_id', userId);
    final theirs = await _client
        .from('friendships')
        .select('friend_id')
        .eq('user_id', otherId);

    final myIds = {
      for (final row in mine as List) row['friend_id'] as String,
    };
    var count = 0;
    for (final row in theirs as List) {
      if (myIds.contains(row['friend_id'] as String)) count++;
    }
    return count;
  }

  Future<List<FriendSummary>> getFriends(String userId) async {
    final data = await _client
        .from('friendships')
        .select('created_at, friend:friend_id(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map(
          (row) => FriendSummaryModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toEntity(),
        )
        .toList();
  }

  Future<List<FriendRequest>> getIncomingRequests(String userId) async {
    final data = await _client
        .from('friend_requests')
        .select(_requestSelect)
        .eq('receiver_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return _mapRequests(data);
  }

  Future<List<FriendRequest>> getOutgoingRequests(String userId) async {
    final data = await _client
        .from('friend_requests')
        .select(_requestSelect)
        .eq('sender_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return _mapRequests(data);
  }

  Future<List<UserProfile>> searchProfiles(String userId, String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return [];

    final data = await _client
        .from('profiles')
        .select()
        .neq('id', userId)
        .or('username.ilike.$normalized%,display_name.ilike.$normalized%')
        .limit(20);

    return (data as List)
        .map(
          (row) => ProfileModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toEntity(),
        )
        .toList();
  }

  Future<UserProfile> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select(
          'id, username, display_name, avatar_url, bio, created_at, last_seen_at',
        )
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(Map<String, dynamic>.from(data)).toEntity();
  }

  Future<DateTime?> getFriendshipSince(String userId, String friendId) async {
    final data = await _client
        .from('friendships')
        .select('created_at')
        .eq('user_id', userId)
        .eq('friend_id', friendId)
        .maybeSingle();
    if (data == null) return null;
    return DateTime.parse(data['created_at'] as String).toUtc();
  }

  Future<bool> areFriends(String userId, String otherId) async {
    final data = await _client
        .from('friendships')
        .select('user_id')
        .eq('user_id', userId)
        .eq('friend_id', otherId)
        .maybeSingle();
    return data != null;
  }

  Future<FriendRequest?> findPendingRequest(
    String userId,
    String otherId,
  ) async {
    final data = await _client
        .from('friend_requests')
        .select(_requestSelect)
        .eq('status', 'pending')
        .or(
          'and(sender_id.eq.$userId,receiver_id.eq.$otherId),'
          'and(sender_id.eq.$otherId,receiver_id.eq.$userId)',
        )
        .maybeSingle();

    if (data == null) return null;
    return FriendRequestModel.fromJson(
      Map<String, dynamic>.from(data),
    ).toEntity();
  }

  Future<bool> hasBlocked(String blockerId, String blockedId) async {
    final data = await _client
        .from('user_blocks')
        .select('blocker_id')
        .eq('blocker_id', blockerId)
        .eq('blocked_id', blockedId)
        .maybeSingle();
    return data != null;
  }

  Future<void> sendFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    await _client.rpc<void>(
      'send_friend_request',
      params: {'p_receiver_id': receiverId},
    );
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _client.rpc<void>(
      'accept_friend_request',
      params: {'request_id': requestId},
    );
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _client
        .from('friend_requests')
        .update({'status': 'rejected'})
        .eq('id', requestId)
        .eq('status', 'pending');
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await _client
        .from('friend_requests')
        .update({'status': 'cancelled'})
        .eq('id', requestId)
        .eq('status', 'pending');
  }

  Future<void> removeFriend(String friendId) async {
    await _client.rpc<void>('remove_friend', params: {'friend': friendId});
  }

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await _client.from('user_blocks').insert({
      'blocker_id': blockerId,
      'blocked_id': blockedId,
    });
  }

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await _client
        .from('user_blocks')
        .delete()
        .eq('blocker_id', blockerId)
        .eq('blocked_id', blockedId);
  }

  Future<List<BlockedUser>> getBlockedUsers(String userId) async {
    final data = await _client
        .from('user_blocks')
        .select('created_at, blocked:blocked_id(*)')
        .eq('blocker_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map(
          (row) => BlockedUserModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toEntity(),
        )
        .toList();
  }

  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? details,
  }) async {
    await _client.from('user_reports').insert({
      'reporter_id': reporterId,
      'reported_id': reportedId,
      'reason': reason,
      if (details != null && details.isNotEmpty) 'details': details,
    });
  }

  Failure mapError(Object error) {
    return mapPostgrestError(
      error,
      fallback: 'Could not update friends. Please try again.',
    );
  }

  List<FriendRequest> _mapRequests(Object? data) {
    return (data as List)
        .map(
          (row) => FriendRequestModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ).toEntity(),
        )
        .toList();
  }
}
