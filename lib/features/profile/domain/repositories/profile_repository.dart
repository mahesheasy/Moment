import 'dart:typed_data';

import 'package:moment/core/result/result.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Result<UserProfile>> getCurrentProfile();

  Future<Result<UserProfile>> updateProfile(ProfileUpdate update);

  Future<Result<UserProfile>> uploadAvatar({
    required Uint8List bytes,
    required String mimeType,
  });

  Future<Result<bool>> isUsernameAvailable(String username);
}
