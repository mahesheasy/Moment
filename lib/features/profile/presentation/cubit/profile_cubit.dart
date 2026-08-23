import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/push/push_registration_service.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/auth/domain/usecases/auth_usecases.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/memories/domain/repositories/memory_repository.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'package:moment/features/profile/domain/usecases/profile_usecases.dart';

enum ProfileStatus { initial, loading, loaded, saving, failure }

class ProfileStats extends Equatable {
  const ProfileStats({
    this.peopleCount = 0,
    this.circlesCount = 0,
    this.memoriesCount = 0,
  });

  final int peopleCount;
  final int circlesCount;
  final int memoriesCount;

  @override
  List<Object?> get props => [peopleCount, circlesCount, memoriesCount];
}

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.stats = const ProfileStats(),
    this.errorMessage,
  });

  final ProfileStatus status;
  final UserProfile? profile;
  final ProfileStats stats;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, profile, stats, errorMessage];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(
    this._getProfile,
    this._updateProfile,
    this._uploadAvatar,
    this._friends,
    this._circles,
    this._memories,
  ) : super(const ProfileState());

  final GetCurrentProfileUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;
  final UploadAvatarUseCase _uploadAvatar;
  final FriendsRepository _friends;
  final CircleRepository _circles;
  final MemoryRepository _memories;

  Future<void> load() async {
    emit(state.copyWithLoading());
    final result = await _getProfile();
    final stats = await _loadStats();
    result.when(
      success: (profile) => emit(
        ProfileState(
          status: ProfileStatus.loaded,
          profile: profile,
          stats: stats,
        ),
      ),
      failure: (failure) => emit(
        ProfileState(
          status: ProfileStatus.failure,
          stats: stats,
          errorMessage: failure.message,
        ),
      ),
    );
  }

  Future<ProfileStats> _loadStats() async {
    final friendsResult = await _friends.getFriends();
    final circlesResult = await _circles.getMyCircles();
    final memoriesResult = await _memories.getMyMemories();

    final peopleCount = switch (friendsResult) {
      Success(:final value) => value.length,
      Failed() => 0,
    };
    final circlesCount = switch (circlesResult) {
      Success(:final value) => value.length,
      Failed() => 0,
    };
    final memoriesCount = switch (memoriesResult) {
      Success(:final value) => value.length,
      Failed() => 0,
    };

    return ProfileStats(
      peopleCount: peopleCount,
      circlesCount: circlesCount,
      memoriesCount: memoriesCount,
    );
  }

  Future<bool> save(
    ProfileUpdate update, {
    Uint8List? avatarBytes,
    String? avatarMimeType,
  }) async {
    emit(
      ProfileState(
        status: ProfileStatus.saving,
        profile: state.profile,
        stats: state.stats,
      ),
    );

    if (avatarBytes != null && avatarMimeType != null) {
      final uploadResult = await _uploadAvatar(
        bytes: avatarBytes,
        mimeType: avatarMimeType,
      );
      final uploaded = uploadResult.when(
        success: (profile) {
          emit(
            ProfileState(
              status: ProfileStatus.saving,
              profile: profile,
              stats: state.stats,
            ),
          );
          return true;
        },
        failure: (failure) {
          emit(
            ProfileState(
              status: ProfileStatus.failure,
              profile: state.profile,
              stats: state.stats,
              errorMessage: failure.message,
            ),
          );
          return false;
        },
      );
      if (!uploaded) return false;
    }

    final result = await _updateProfile(update);
    return result.when(
      success: (profile) {
        emit(
          ProfileState(
            status: ProfileStatus.loaded,
            profile: profile,
            stats: state.stats,
          ),
        );
        return true;
      },
      failure: (failure) {
        emit(
          ProfileState(
            status: ProfileStatus.failure,
            profile: state.profile,
            stats: state.stats,
            errorMessage: failure.message,
          ),
        );
        return false;
      },
    );
  }
}

extension on ProfileState {
  ProfileState copyWithLoading() {
    return ProfileState(
      status: ProfileStatus.loading,
      profile: profile,
      stats: stats,
    );
  }
}

class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._logout, this._deleteAccount, this._push)
    : super(const AccountState());

  final LogoutUseCase _logout;
  final DeleteAccountUseCase _deleteAccount;
  final PushRegistrationService _push;

  Future<void> logout() async {
    emit(const AccountState.loading());
    // Has to run before the session is torn down: the RPC needs auth.uid(),
    // and otherwise this device keeps receiving the old user's moments.
    await _push.unregister();
    final result = await _logout();
    result.when(
      success: (_) => emit(const AccountState.success()),
      failure: (failure) => emit(AccountState.failure(failure.message)),
    );
  }

  Future<void> deleteAccount() async {
    emit(const AccountState.loading());
    await _push.unregister();
    final result = await _deleteAccount();
    result.when(
      success: (_) => emit(const AccountState.deleted()),
      failure: (failure) => emit(AccountState.failure(failure.message)),
    );
  }
}

class AccountState extends Equatable {
  const AccountState({
    this.isLoading = false,
    this.errorMessage,
    this.deleted = false,
  });

  const AccountState.loading() : this(isLoading: true);
  const AccountState.success() : this();
  const AccountState.deleted() : this(deleted: true);
  const AccountState.failure(String message)
    : this(errorMessage: message, isLoading: false);

  final bool isLoading;
  final String? errorMessage;
  final bool deleted;

  @override
  List<Object?> get props => [isLoading, errorMessage, deleted];
}
