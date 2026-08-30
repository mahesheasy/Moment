import 'dart:typed_data';

import 'package:moment/core/errors/failures.dart';
import 'package:moment/features/circles/data/circle_image_resolver.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/moments/data/datasources/moments_remote_data_source.dart';
import 'package:moment/features/profile/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CirclesRemoteDataSource {
  CirclesRemoteDataSource(this._client, this._imageResolver, this._moments);

  final SupabaseClient _client;
  final CircleImageResolver _imageResolver;
  final MomentsRemoteDataSource _moments;
  static const _avatarsBucket = 'circle-avatars';

  Future<List<Circle>> getMyCircles(String userId) async {
    final memberships = await _client
        .from('circle_members')
        .select('circle_id')
        .eq('user_id', userId);

    final circleIds = (memberships as List)
        .map((row) => (row as Map)['circle_id'] as String)
        .toList();

    if (circleIds.isEmpty) return [];

    final data = await _client
        .from('circles')
        .select('*, members:circle_members(count)')
        .inFilter('id', circleIds)
        .order('created_at', ascending: false);

    return Future.wait((data as List).map((row) => _mapCircle(row)));
  }

  Future<Map<String, CircleActivitySummary>> getCircleActivitySummaries(
    List<String> circleIds,
  ) async {
    if (circleIds.isEmpty) return {};

    final summaries = <String, CircleActivitySummary>{};

    await Future.wait(
      circleIds.map((circleId) async {
        final moments = await _moments.listMomentsSharedToCircle(
          circleId: circleId,
        );
        if (moments.isEmpty) {
          summaries[circleId] = const CircleActivitySummary();
          return;
        }

        final latest = moments.first;
        summaries[circleId] = CircleActivitySummary(
          momentCount: moments.length,
          latestSenderName: latest.sender.displayName,
          latestActivityAt: latest.createdAt,
          latestImageUrl: latest.imageUrl,
        );
      }),
    );

    return summaries;
  }

  Future<Circle> getCircle(String circleId) async {
    final data = await _client
        .from('circles')
        .select('*, members:circle_members(count)')
        .eq('id', circleId)
        .single();
    return _mapCircle(data);
  }

  Future<List<CircleMember>> getCircleMembers(String circleId) async {
    final grouped = await getMembersForCircles([circleId]);
    return grouped[circleId] ?? const [];
  }

  Future<Map<String, List<CircleMember>>> getMembersForCircles(
    List<String> circleIds,
  ) async {
    if (circleIds.isEmpty) return {};

    final data = await _client
        .from('circle_members')
        .select('circle_id, role, joined_at, profile:user_id(*)')
        .inFilter('circle_id', circleIds)
        .order('joined_at');

    final grouped = <String, List<CircleMember>>{};
    for (final row in data as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = map['circle_id'] as String;
      grouped.putIfAbsent(id, () => []).add(
        CircleMember(
          profile: ProfileModel.fromJson(
            Map<String, dynamic>.from(map['profile'] as Map),
          ).toEntity(),
          role: map['role'] as String,
          joinedAt: DateTime.parse(map['joined_at'] as String),
        ),
      );
    }
    return grouped;
  }

  Future<Circle> createCircle({
    required String name,
    required CircleType type,
    String? emoji,
    required List<String> memberIds,
  }) async {
    final created = await _client.rpc<Map<String, dynamic>>(
      'create_circle_with_owner',
      params: {
        'p_name': name.trim(),
        'p_circle_type': type.value,
        'p_emoji': emoji,
      },
    );

    final circleId = created['id'] as String;

    if (memberIds.isNotEmpty) {
      await _client
          .from('circle_members')
          .insert(
            memberIds
                .map((userId) => {'circle_id': circleId, 'user_id': userId})
                .toList(),
          );
    }

    return getCircle(circleId);
  }

  Future<void> addMember({
    required String circleId,
    required String userId,
  }) async {
    await _client.from('circle_members').insert({
      'circle_id': circleId,
      'user_id': userId,
    });
  }

  Future<void> removeMember({
    required String circleId,
    required String userId,
  }) async {
    await _client
        .from('circle_members')
        .delete()
        .eq('circle_id', circleId)
        .eq('user_id', userId);
  }

  Future<Circle> uploadCircleAvatar({
    required String circleId,
    required String ownerId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final circle = await getCircle(circleId);
    if (circle.ownerId != ownerId) {
      throw const ValidationFailure(
        message: 'Only the circle owner can change the photo.',
      );
    }

    final extension = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final storagePath = '$circleId/avatar.$extension';

    await _client.storage.from(_avatarsBucket).uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: true),
    );

    _imageResolver.invalidate(storagePath);

    final data = await _client
        .from('circles')
        .update({'avatar_url': storagePath})
        .eq('id', circleId)
        .select('*, members:circle_members(count)')
        .single();

    return _mapCircle(data);
  }

  Future<Circle> _mapCircle(Object? data) async {
    final map = Map<String, dynamic>.from(data! as Map);
    final members = map['members'];
    var count = 0;
    if (members is List && members.isNotEmpty) {
      final first = Map<String, dynamic>.from(members.first as Map);
      count = first['count'] as int? ?? 0;
    }

    final avatarPath = map['avatar_url'] as String?;

    return Circle(
      id: map['id'] as String,
      name: map['name'] as String,
      type: CircleType.fromValue(map['circle_type'] as String),
      ownerId: map['owner_id'] as String,
      emoji: map['emoji'] as String?,
      avatarUrl: avatarPath,
      memberCount: count,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Future<Circle> updateCircleName({
    required String circleId,
    required String name,
  }) async {
    final data = await _client
        .from('circles')
        .update({'name': name.trim()})
        .eq('id', circleId)
        .select('*, members:circle_members(count)')
        .single();

    return _mapCircle(data);
  }

  Future<void> deleteCircle(String circleId) async {
    await _client.from('circles').delete().eq('id', circleId);
  }

  Failure mapError(Object error) {
    if (error is PostgrestException) {
      if (error.code == '23505') {
        return const ValidationFailure(
          message: 'That member is already in the circle.',
        );
      }
      if (error.message.contains('at most 20 members')) {
        return const ValidationFailure(
          message: 'A circle can have at most 20 members.',
        );
      }
      if (error.message.contains('avatar_url')) {
        return const StorageFailure(
          message: 'Circle photos are not available yet. Please update the app.',
        );
      }
      return DatabaseFailure(cause: error);
    }
    if (error is StorageException) {
      final code = error.statusCode?.toString();
      final message = switch (code) {
        '401' || '403' =>
          'You do not have permission to upload this photo.',
        '404' => 'Photo storage is not available yet.',
        '413' => 'That photo is too large (max 5 MB).',
        _ when error.message.toLowerCase().contains('mime') =>
          'That image format is not supported. Use JPEG, PNG, or WebP.',
        _ => 'We could not save that photo. Please try again.',
      };
      return StorageFailure(message: message, cause: error);
    }
    if (error is Failure) return error;
    return UnknownFailure(cause: error);
  }
}
