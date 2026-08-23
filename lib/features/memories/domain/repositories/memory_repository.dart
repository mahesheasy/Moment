import 'package:moment/core/result/result.dart';
import 'package:moment/features/memories/domain/entities/memory.dart';
import 'package:moment/features/memories/domain/entities/memory_theme.dart';
import 'dart:typed_data';

abstract class MemoryRepository {
  Future<Result<List<MemorySummary>>> getMyMemories();

  Future<Result<MemoryDetail>> getMemory(String memoryId);

  Future<Result<MemoryThemeCatalog>> getThemeCatalog();

  Future<Result<MemorySummary>> createFromPromptResponses(
    CreateMemoryFromPromptInput input,
  );

  Future<Result<MemorySummary>> createAdvancedMemory(
    CreateAdvancedMemoryInput input,
  );

  Future<Result<MemorySummary>> updateMemory(UpdateMemoryInput input);

  Future<Result<MemorySummary>> uploadCover({
    required String memoryId,
    required Uint8List bytes,
    required String mimeType,
  });

  Future<Result<MemoryChapter>> upsertChapter(UpsertMemoryChapterInput input);

  Future<Result<void>> deleteChapter(String chapterId);

  Future<Result<void>> deleteMemory(String memoryId);
}
