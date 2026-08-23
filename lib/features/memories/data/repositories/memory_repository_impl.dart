import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/memories/data/datasources/memories_remote_data_source.dart';
import 'package:moment/features/memories/domain/entities/memory.dart';
import 'package:moment/features/memories/domain/entities/memory_theme.dart';
import 'package:moment/features/memories/domain/repositories/memory_repository.dart';
import 'package:moment/features/subscription/domain/repositories/subscription_repository.dart';
import 'dart:typed_data';

class MemoryRepositoryImpl implements MemoryRepository {
  MemoryRepositoryImpl(this._remote, this._subscriptions, this._userIdProvider);

  final MemoriesRemoteDataSource _remote;
  final SubscriptionRepository _subscriptions;
  final String? Function() _userIdProvider;

  @override
  Future<Result<List<MemorySummary>>> getMyMemories() async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getAccessibleMemories(userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<MemoryDetail>> getMemory(String memoryId) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getMemoryDetail(memoryId, userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<MemoryThemeCatalog>> getThemeCatalog() async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getThemeCatalog());
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<MemorySummary>> createFromPromptResponses(
    CreateMemoryFromPromptInput input,
  ) async {
    return _createMemory(() async {
      return _remote.createFromPromptResponses(
        title: input.title,
        circleId: input.circleId,
        promptId: input.promptId,
      );
    }, input.title);
  }

  @override
  Future<Result<MemorySummary>> createAdvancedMemory(
    CreateAdvancedMemoryInput input,
  ) async {
    return _createMemory(() async {
      return _remote.createAdvancedMemory(
        title: input.title,
        memoryType: input.memoryType,
        caption: input.caption,
        theme: input.theme,
        memoryDate: input.memoryDate,
        circleId: input.circleId,
      );
    }, input.title);
  }

  @override
  Future<Result<MemorySummary>> updateMemory(UpdateMemoryInput input) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    final title = input.title.trim();
    if (title.isEmpty) {
      return const Failed(
        ValidationFailure(message: 'Give your memory a title.'),
      );
    }

    try {
      return Success(
        await _remote.updateMemory(
          memoryId: input.memoryId,
          title: title,
          caption: input.caption,
          theme: input.theme,
          memoryDate: input.memoryDate,
          coverMomentId: input.coverMomentId,
          coverStoragePath: input.coverStoragePath,
        ),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<MemorySummary>> uploadCover({
    required String memoryId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final userId = _userIdProvider();
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(
        await _remote.uploadCover(
          userId: userId,
          memoryId: memoryId,
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
  Future<Result<MemoryChapter>> upsertChapter(
    UpsertMemoryChapterInput input,
  ) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    final title = input.title.trim();
    if (title.isEmpty) {
      return const Failed(
        ValidationFailure(message: 'Give the chapter a title.'),
      );
    }

    try {
      return Success(
        await _remote.upsertChapter(
          memoryId: input.memoryId,
          title: title,
          chapterId: input.chapterId,
          caption: input.caption,
          position: input.position,
        ),
      );
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> deleteChapter(String chapterId) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.deleteChapter(chapterId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> deleteMemory(String memoryId) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.deleteMemory(memoryId);
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  Future<Result<MemorySummary>> _createMemory(
    Future<MemorySummary> Function() create,
    String title,
  ) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    if (title.trim().isEmpty) {
      return const Failed(
        ValidationFailure(message: 'Give your memory a title.'),
      );
    }

    try {
      final offeringResult = await _subscriptions.getOffering();
      if (offeringResult case Success(:final value)) {
        if (!value.canCreateMemory) {
          return Failed(
            ValidationFailure(
              message:
                  'Free plan includes ${value.limits.freeMemoryLimit} saved memories. '
                  'Upgrade to Moment+ for unlimited.',
            ),
          );
        }
      }

      return Success(await create());
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }
}
