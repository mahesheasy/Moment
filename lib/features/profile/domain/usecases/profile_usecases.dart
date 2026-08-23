import 'dart:typed_data';

import 'package:moment/core/result/result.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'package:moment/features/profile/domain/repositories/profile_repository.dart';

class GetCurrentProfileUseCase {
  const GetCurrentProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Result<UserProfile>> call() => _repository.getCurrentProfile();
}

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Result<UserProfile>> call(ProfileUpdate update) =>
      _repository.updateProfile(update);
}

class UploadAvatarUseCase {
  const UploadAvatarUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Result<UserProfile>> call({
    required Uint8List bytes,
    required String mimeType,
  }) =>
      _repository.uploadAvatar(bytes: bytes, mimeType: mimeType);
}

class CheckUsernameAvailabilityUseCase {
  const CheckUsernameAvailabilityUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Result<bool>> call(String username) =>
      _repository.isUsernameAvailable(username);
}
