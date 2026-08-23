import 'dart:typed_data';

import 'package:moment/core/errors/exception_mapper.dart';
import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/auth/domain/validators/auth_validators.dart';
import 'package:moment/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'package:moment/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, this._userIdProvider, this._mapper);

  final ProfileRemoteDataSource _remote;
  final String? Function() _userIdProvider;
  final ExceptionMapper _mapper;

  @override
  Future<Result<UserProfile>> getCurrentProfile() async {
    final userId = _userIdProvider();
    if (userId == null) {
      return const Failed(AuthenticationFailure());
    }

    try {
      return Success(await _remote.getProfile(userId));
    } on Object catch (error, stackTrace) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<UserProfile>> updateProfile(ProfileUpdate update) async {
    final userId = _userIdProvider();
    if (userId == null) {
      return const Failed(AuthenticationFailure());
    }

    String? username = update.username?.trim().toLowerCase();
    if (username != null) {
      final usernameError = AuthValidators.validateUsername(username);
      if (usernameError != null) return Failed(usernameError);
    } else {
      username = null;
    }

    try {
      return Success(
        await _remote.updateProfile(
          userId: userId,
          update: ProfileUpdate(
            displayName: update.displayName?.trim(),
            username: username,
            bio: update.bio?.trim(),
            avatarUrl: update.avatarUrl,
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<UserProfile>> uploadAvatar({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final userId = _userIdProvider();
    if (userId == null) {
      return const Failed(AuthenticationFailure());
    }

    try {
      return Success(
        await _remote.uploadAvatar(
          userId: userId,
          bytes: bytes,
          mimeType: mimeType,
        ),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<bool>> isUsernameAvailable(String username) async {
    try {
      return Success(await _remote.isUsernameAvailable(username));
    } on Object catch (error, stackTrace) {
      return Failed(_mapper.map(error, stackTrace));
    }
  }
}
