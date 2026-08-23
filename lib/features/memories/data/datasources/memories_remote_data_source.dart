import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/errors/postgrest_mapper.dart';
import 'package:moment/features/memories/domain/entities/memory.dart';
import 'package:moment/features/memories/domain/entities/memory_theme.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/profile/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class MemoriesRemoteDataSource {
  MemoriesRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const _momentsBucket = 'moments';
  static const _coversBucket = 'memory-covers';

  Future<List<MemorySummary>> getAccessibleMemories(String userId) async {
    const select =
        '*, items:memory_items(count), participants:memory_participants(count), cover:cover_moment_id(storage_path)';

    final owned = await _client
        .from('memories')
        .select(select)
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    final participantRows = await _client
        .from('memory_participants')
        .select('memory_id')
        .eq('user_id', userId);

    final participantIds = (participantRows as List)
        .map((row) => (row as Map)['memory_id'] as String)
        .toSet();

    final ownedIds = (owned as List)
        .map((row) => (row as Map)['id'] as String)
        .toSet();

    final sharedIds = participantIds.difference(ownedIds).toList();
    final shared = sharedIds.isEmpty
        ? <dynamic>[]
        : await _client
              .from('memories')
              .select(select)
              .inFilter('id', sharedIds)
              .order('created_at', ascending: false);

    final rows = [...owned, ...shared];
    return Future.wait(
      rows.map((row) => _mapMemorySummary(row, viewerId: userId)),
    );
  }

  Future<MemorySummary> getMemorySummary(String memoryId) async {
    final data = await _client
        .from('memories')
        .select(
          '*, items:memory_items(count), participants:memory_participants(count), cover:cover_moment_id(storage_path)',
        )
        .eq('id', memoryId)
        .single();
    return _mapMemorySummary(data);
  }

  Future<MemoryDetail> getMemoryDetail(String memoryId, String userId) async {
    final summary = await getMemorySummary(memoryId);

    final itemsData = await _client
        .from('memory_items')
        .select(
          'position, chapter_id, moment:moment_id(*, sender:sender_id(*))',
        )
        .eq('memory_id', memoryId)
        .order('position');

    final items = <MemoryTimelineItem>[];
    for (final row in itemsData as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final momentJson = Map<String, dynamic>.from(map['moment'] as Map);
      final moment = await _mapMoment(momentJson);
      items.add(
        MemoryTimelineItem(
          moment: moment,
          position: map['position'] as int? ?? 0,
          chapterId: map['chapter_id'] as String?,
        ),
      );
    }

    final participantsData = await _client
        .from('memory_participants')
        .select('profile:user_id(*)')
        .eq('memory_id', memoryId);

    final participants = (participantsData as List)
        .map((row) {
          final map = Map<String, dynamic>.from(row as Map);
          return ProfileModel.fromJson(
            Map<String, dynamic>.from(map['profile'] as Map),
          ).toEntity();
        })
        .toList(growable: false);

    final chaptersData = await _client
        .from('memory_chapters')
        .select('*')
        .eq('memory_id', memoryId)
        .order('position');

    final chapters = (chaptersData as List)
        .map((row) => _mapChapter(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);

    return MemoryDetail(
      summary: summary,
      items: items,
      participants: participants,
      chapters: chapters,
      isOwner: summary.ownerId == userId,
    );
  }

  Future<MemoryThemeCatalog> getThemeCatalog() async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'get_memory_theme_catalog',
    );
    return MemoryThemeCatalog(
      themes: (data['themes'] as List)
          .map((value) => MemoryTheme.fromValue(value as String))
          .toList(),
      memoryTypes: (data['memory_types'] as List)
          .map((value) => MemoryType.fromValue(value as String))
          .where((type) => type != MemoryType.prompt)
          .toList(),
      isPremium: data['is_premium'] as bool? ?? false,
    );
  }

  Future<MemorySummary> createFromPromptResponses({
    required String title,
    required String circleId,
    required String promptId,
  }) async {
    final created = await _client.rpc<Map<String, dynamic>>(
      'create_memory_from_prompt_responses',
      params: {
        'p_title': title.trim(),
        'p_circle_id': circleId,
        'p_prompt_id': promptId,
      },
    );

    return getMemorySummary(created['id'] as String);
  }

  Future<MemorySummary> createAdvancedMemory({
    required String title,
    required MemoryType memoryType,
    String? caption,
    MemoryTheme theme = MemoryTheme.minimal,
    DateTime? memoryDate,
    String? circleId,
  }) async {
    final created = await _client.rpc<Map<String, dynamic>>(
      'create_advanced_memory',
      params: {
        'p_title': title.trim(),
        'p_memory_type': memoryType.name,
        'p_caption': caption?.trim(),
        'p_theme': theme.name,
        'p_memory_date': memoryDate == null
            ? null
            : _formatDateParam(memoryDate),
        'p_circle_id': circleId,
      },
    );

    return getMemorySummary(created['id'] as String);
  }

  Future<MemorySummary> updateMemory({
    required String memoryId,
    required String title,
    String? caption,
    MemoryTheme theme = MemoryTheme.minimal,
    DateTime? memoryDate,
    String? coverMomentId,
    String? coverStoragePath,
  }) async {
    await _client.rpc<Map<String, dynamic>>(
      'update_memory_advanced',
      params: {
        'p_memory_id': memoryId,
        'p_title': title.trim(),
        'p_caption': caption?.trim(),
        'p_theme': theme.name,
        'p_memory_date': memoryDate == null
            ? null
            : _formatDateParam(memoryDate),
        'p_cover_moment_id': coverMomentId,
        'p_cover_storage_path': coverStoragePath,
      },
    );

    return getMemorySummary(memoryId);
  }

  Future<MemorySummary> uploadCover({
    required String userId,
    required String memoryId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final extension = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final storagePath = '$userId/$memoryId/cover.$extension';

    await _client.storage
        .from(_coversBucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    final summary = await getMemorySummary(memoryId);

    return updateMemory(
      memoryId: memoryId,
      title: summary.title,
      caption: summary.caption,
      theme: summary.theme,
      memoryDate: summary.memoryDate,
      coverMomentId: summary.coverMomentId,
      coverStoragePath: storagePath,
    );
  }

  Future<MemoryChapter> upsertChapter({
    required String memoryId,
    required String title,
    String? chapterId,
    String? caption,
    int position = 0,
  }) async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'upsert_memory_chapter',
      params: {
        'p_memory_id': memoryId,
        'p_title': title.trim(),
        'p_chapter_id': chapterId,
        'p_caption': caption?.trim(),
        'p_position': position,
      },
    );

    return _mapChapter(data);
  }

  Future<void> deleteChapter(String chapterId) async {
    await _client.rpc<void>(
      'delete_memory_chapter',
      params: {'p_chapter_id': chapterId},
    );
  }

  Future<void> deleteMemory(String memoryId) async {
    await _client.from('memories').delete().eq('id', memoryId);
  }

  MemoryChapter _mapChapter(Map<String, dynamic> map) {
    final startsAt = map['starts_at'] as String?;
    final endsAt = map['ends_at'] as String?;
    return MemoryChapter(
      id: map['id'] as String,
      title: map['title'] as String,
      position: map['position'] as int? ?? 0,
      caption: map['caption'] as String?,
      startsAt: startsAt == null ? null : DateTime.parse(startsAt),
      endsAt: endsAt == null ? null : DateTime.parse(endsAt),
    );
  }

  Future<MemorySummary> _mapMemorySummary(
    Object? data, {
    String? viewerId,
  }) async {
    final map = Map<String, dynamic>.from(data! as Map);
    final items = map['items'];
    final participants = map['participants'];
    var momentCount = 0;
    var participantCount = 0;

    if (items is List && items.isNotEmpty) {
      momentCount =
          (Map<String, dynamic>.from(items.first as Map)['count'] as int?) ?? 0;
    }
    if (participants is List && participants.isNotEmpty) {
      participantCount =
          Map<String, dynamic>.from(participants.first as Map)['count']
              as int? ??
          0;
    }

    final startsAt = map['starts_at'] as String?;
    final endsAt = map['ends_at'] as String?;
    final memoryDateRaw = map['memory_date'] as String?;
    final start = startsAt == null ? null : DateTime.parse(startsAt);
    final end = endsAt == null ? null : DateTime.parse(endsAt);
    final memoryDate = memoryDateRaw == null
        ? null
        : DateTime.parse(memoryDateRaw);
    final dayCount = _daySpan(start, end);

    String? coverImageUrl;
    final coverStoragePath = map['cover_storage_path'] as String?;
    if (coverStoragePath != null && coverStoragePath.isNotEmpty) {
      coverImageUrl = await _client.storage
          .from(_coversBucket)
          .createSignedUrl(coverStoragePath, 3600);
    } else {
      final cover = map['cover'];
      if (cover is Map) {
        final storagePath = cover['storage_path'] as String?;
        if (storagePath != null) {
          coverImageUrl = await _client.storage
              .from(_momentsBucket)
              .createSignedUrl(storagePath, 3600);
        }
      }
    }

    return MemorySummary(
      id: map['id'] as String,
      title: map['title'] as String,
      ownerId: map['owner_id'] as String,
      isOwner: viewerId != null && map['owner_id'] == viewerId,
      momentCount: momentCount,
      participantCount: participantCount,
      dayCount: dayCount,
      createdAt: DateTime.parse(map['created_at'] as String),
      memoryType: MemoryType.fromValue(
        map['memory_type'] as String? ?? 'custom',
      ),
      theme: MemoryTheme.fromValue(map['theme'] as String? ?? 'minimal'),
      caption: map['caption'] as String?,
      coverImageUrl: coverImageUrl,
      startsAt: start,
      endsAt: end,
      memoryDate: memoryDate,
      circleId: map['circle_id'] as String?,
      promptId: map['prompt_id'] as String?,
      coverMomentId: map['cover_moment_id'] as String?,
    );
  }

  Future<Moment> _mapMoment(Map<String, dynamic> json) async {
    final storagePath = json['storage_path'] as String;
    final imageUrl = await _client.storage
        .from(_momentsBucket)
        .createSignedUrl(storagePath, 3600);
    final sender = ProfileModel.fromJson(
      Map<String, dynamic>.from(json['sender'] as Map),
    ).toEntity();

    return Moment(
      id: json['id'] as String,
      sender: sender,
      storagePath: storagePath,
      imageUrl: imageUrl,
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String _formatDateParam(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  int _daySpan(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 1;
    final diff = end.toLocal().difference(start.toLocal()).inDays;
    return diff <= 0 ? 1 : diff + 1;
  }

  Failure mapError(Object error) {
    if (error is PostgrestException) {
      if (error.code == '23505') {
        return const ValidationFailure(
          message: 'You already saved this day as a memory.',
        );
      }
      if (error.message.contains('No prompt responses')) {
        return const ValidationFailure(
          message: 'Add prompt responses before saving a memory.',
        );
      }
      if (error.message.contains('Moment+ required')) {
        return mapPostgrestError(
          error,
          fallback: 'Moment+ required for this feature.',
        );
      }
      return mapPostgrestError(
        error,
        fallback: 'Could not save memory. Please try again.',
      );
    }
    if (error is StorageException) {
      return StorageFailure(cause: error);
    }
    if (error is Failure) return error;
    return UnknownFailure(cause: error);
  }
}
