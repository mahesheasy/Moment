import 'dart:typed_data';

import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/errors/postgrest_mapper.dart' as pg;
import 'package:moment/features/profile/data/avatar_url_resolver.dart';
import 'package:moment/features/profile/data/models/profile_model.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._client, this._avatarResolver);

  final SupabaseClient _client;
  final AvatarUrlResolver _avatarResolver;
  static const _avatarsBucket = 'avatars';

  Future<UserProfile> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return _mapProfile(Map<String, dynamic>.from(data));
  }

  Future<UserProfile> createProfile({
    required String userId,
    required String username,
    required String displayName,
  }) async {
    final data = await _client
        .from('profiles')
        .insert({
          'id': userId,
          'username': username,
          'display_name': displayName,
        })
        .select()
        .single();
    return _mapProfile(Map<String, dynamic>.from(data));
  }

  Future<UserProfile> updateProfile({
    required String userId,
    required ProfileUpdate update,
  }) async {
    final payload = update.toJson();
    if (payload.isEmpty) {
      return getProfile(userId);
    }

    final data = await _client
        .from('profiles')
        .update(payload)
        .eq('id', userId)
        .select()
        .single();
    return _mapProfile(Map<String, dynamic>.from(data));
  }

  Future<UserProfile> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final extension = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final storagePath = '$userId/avatar.$extension';

    await _client.storage.from(_avatarsBucket).uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: true),
    );

    _avatarResolver.invalidate(storagePath);

    return updateProfile(
      userId: userId,
      update: ProfileUpdate(avatarUrl: storagePath),
    );
  }

  Future<UserProfile> _mapProfile(Map<String, dynamic> json) async {
    final model = ProfileModel.fromJson(json);
    final avatarUrl = await _avatarResolver.resolve(model.avatarUrl);
    return model.toEntity().copyWith(avatarUrl: avatarUrl);
  }

  Future<bool> isUsernameAvailable(String username) async {
    final data = await _client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return data == null;
  }

  Failure mapPostgrestError(Object error) {
    if (error is PostgrestException && error.code == '23505') {
      return const ValidationFailure(
        message: 'That username is already taken.',
      );
    }
    return pg.mapPostgrestError(
      error,
      fallback: 'Could not update profile. Please try again.',
    );
  }
}
