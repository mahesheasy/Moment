import 'dart:typed_data';

import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/circles/data/datasources/circles_remote_data_source.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';

class CircleRepositoryImpl implements CircleRepository {
  CircleRepositoryImpl(this._remote, this._friends, this._userIdProvider);

  final CirclesRemoteDataSource _remote;
  final FriendsRepository _friends;
  final String? Function() _userIdProvider;

  String? get _userId => _userIdProvider();

  @override
  Future<Result<List<Circle>>> getMyCircles() async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getMyCircles(userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<Map<String, CircleActivitySummary>>> getCircleActivitySummaries(
    List<String> circleIds,
  ) async {
    if (_userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getCircleActivitySummaries(circleIds));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<Map<String, List<CircleMember>>>> getMembersForCircles(
    List<String> circleIds,
  ) async {
    if (_userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getMembersForCircles(circleIds));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<Circle>> getCircle(String circleId) async {
    if (_userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getCircle(circleId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<List<CircleMember>>> getCircleMembers(String circleId) async {
    if (_userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getCircleMembers(circleId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<Circle>> createCircle(CreateCircleInput input) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    final name = input.name.trim();
    if (name.isEmpty) {
      return const Failed(
        ValidationFailure(message: 'Give your circle a name.'),
      );
    }

    try {
      final friendIds = await _friendIds(userId);
      final invited = input.memberIds.where((id) => id != userId).toSet();
      if (1 + invited.length > CircleLimits.maxMembers) {
        return const Failed(
          ValidationFailure(
            message: 'A circle can have at most ${CircleLimits.maxMembers} members.',
          ),
        );
      }

      for (final memberId in invited) {
        if (!friendIds.contains(memberId)) {
          return const Failed(
            ValidationFailure(message: 'You can only add friends to a circle.'),
          );
        }
      }

      return Success(
        await _remote.createCircle(
          name: name,
          type: input.type,
          emoji: input.emoji,
          memberIds: invited.toList(),
        ),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> addMember({
    required String circleId,
    required String userId,
  }) async {
    final currentUserId = _userId;
    if (currentUserId == null) return const Failed(AuthenticationFailure());
    if (currentUserId == userId) {
      return const Failed(
        ValidationFailure(message: 'You are already in this circle.'),
      );
    }

    try {
      final circle = await _remote.getCircle(circleId);
      if (circle.ownerId != currentUserId) {
        return const Failed(
          ValidationFailure(message: 'Only the circle owner can add members.'),
        );
      }
      if (circle.memberCount >= CircleLimits.maxMembers) {
        return const Failed(
          ValidationFailure(
            message:
                'A circle can have at most ${CircleLimits.maxMembers} members.',
          ),
        );
      }

      final friendIds = await _friendIds(currentUserId);
      if (!friendIds.contains(userId)) {
        return const Failed(
          ValidationFailure(message: 'You can only add friends to a circle.'),
        );
      }

      await _remote.addMember(circleId: circleId, userId: userId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> removeMember({
    required String circleId,
    required String userId,
  }) async {
    final currentUserId = _userId;
    if (currentUserId == null) return const Failed(AuthenticationFailure());

    try {
      final circle = await _remote.getCircle(circleId);
      final isOwner = circle.ownerId == currentUserId;
      if (!isOwner && currentUserId != userId) {
        return const Failed(
          ValidationFailure(message: 'You cannot remove this member.'),
        );
      }
      if (isOwner && userId == currentUserId) {
        return const Failed(
          ValidationFailure(
            message: 'The owner cannot leave their own circle.',
          ),
        );
      }

      await _remote.removeMember(circleId: circleId, userId: userId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<Circle>> uploadCircleAvatar({
    required String circleId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(
        await _remote.uploadCircleAvatar(
          circleId: circleId,
          ownerId: userId,
          bytes: bytes,
          mimeType: mimeType,
        ),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<Circle>> updateCircleName({
    required String circleId,
    required String name,
  }) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Failed(ValidationFailure(message: 'Circle name cannot be empty.'));
    }

    try {
      final circle = await _remote.getCircle(circleId);
      if (circle.ownerId != userId) {
        return const Failed(
          ValidationFailure(
            message: 'Only the circle owner can rename this circle.',
          ),
        );
      }

      return Success(
        await _remote.updateCircleName(circleId: circleId, name: trimmed),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> leaveCircle({required String circleId}) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      final circle = await _remote.getCircle(circleId);
      if (circle.ownerId == userId) {
        return const Failed(
          ValidationFailure(
            message: 'As the owner, delete the circle instead of leaving.',
          ),
        );
      }

      await _remote.removeMember(circleId: circleId, userId: userId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> deleteCircle({required String circleId}) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      final circle = await _remote.getCircle(circleId);
      if (circle.ownerId != userId) {
        return const Failed(
          ValidationFailure(
            message: 'Only the circle owner can delete this circle.',
          ),
        );
      }

      await _remote.deleteCircle(circleId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  Future<Set<String>> _friendIds(String userId) async {
    final result = await _friends.getFriends();
    switch (result) {
      case Success(:final value):
        return {for (final friend in value) friend.profile.id};
      case Failed():
        return {};
    }
  }
}
