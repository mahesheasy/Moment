import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/memories/domain/entities/daily_category.dart';
import 'package:moment/features/memories/domain/entities/memory.dart';
import 'package:moment/features/memories/domain/entities/memory_theme.dart';
import 'package:moment/features/memories/domain/repositories/memory_repository.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/moments/domain/entities/reaction.dart';
import 'package:moment/features/moments/domain/repositories/moment_repository.dart';
import 'package:moment/features/moments/domain/repositories/social_repository.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'dart:typed_data';

enum MemoryVaultStatus { initial, loading, loaded, saving, failure }

class MemoryVaultState extends Equatable {
  const MemoryVaultState({
    this.status = MemoryVaultStatus.initial,
    this.memories = const [],
    this.recentMoments = const [],
    this.dailyCategories = const [],
    this.reactionsByMomentId = const {},
    this.filterType,
    this.errorMessage,
  });

  final MemoryVaultStatus status;
  final List<MemorySummary> memories;
  final List<Moment> recentMoments;
  final List<DailyCategory> dailyCategories;
  final Map<String, MomentReactionSummary> reactionsByMomentId;
  final MemoryType? filterType;
  final String? errorMessage;

  List<MemorySummary> get filteredMemories {
    final filter = filterType;
    if (filter == null) return memories;
    return memories.where((memory) => memory.memoryType == filter).toList();
  }

  MemoryVaultState copyWith({
    MemoryVaultStatus? status,
    List<MemorySummary>? memories,
    List<Moment>? recentMoments,
    List<DailyCategory>? dailyCategories,
    Map<String, MomentReactionSummary>? reactionsByMomentId,
    MemoryType? filterType,
    String? errorMessage,
    bool clearError = false,
    bool clearFilter = false,
  }) {
    return MemoryVaultState(
      status: status ?? this.status,
      memories: memories ?? this.memories,
      recentMoments: recentMoments ?? this.recentMoments,
      dailyCategories: dailyCategories ?? this.dailyCategories,
      reactionsByMomentId:
          reactionsByMomentId ?? this.reactionsByMomentId,
      filterType: clearFilter ? null : filterType ?? this.filterType,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    memories,
    recentMoments,
    dailyCategories,
    reactionsByMomentId,
    filterType,
    errorMessage,
  ];
}

class MemoryVaultCubit extends Cubit<MemoryVaultState> {
  MemoryVaultCubit(this._memories, this._moments, this._circles, this._social)
    : super(const MemoryVaultState());

  final MemoryRepository _memories;
  final MomentRepository _moments;
  final CircleRepository _circles;
  final SocialRepository _social;
  List<Circle> _cachedCircles = const [];
  Map<String, List<UserProfile>> _cachedMembers = const {};

  void setFilter(MemoryType? type) {
    emit(state.copyWith(filterType: type, clearFilter: type == null));
  }

  Future<void> refreshDaily() async {
    final recent = await _loadCameraRollMoments();
    if (isClosed) return;
    emit(
      state.copyWith(
        status: MemoryVaultStatus.loaded,
        recentMoments: recent,
        dailyCategories: _categoriesFor(recent),
        reactionsByMomentId: await _loadReactionsForMoments(recent),
      ),
    );
  }

  Future<void> load() async {
    emit(state.copyWith(status: MemoryVaultStatus.loading, clearError: true));

    final vaultResult = await _memories.getMyMemories();
    final recent = await _loadCameraRollMoments();
    await _loadCircleMembership();

    switch (vaultResult) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: MemoryVaultStatus.loaded,
            memories: value,
            recentMoments: recent,
            dailyCategories: _categoriesFor(recent),
            reactionsByMomentId: await _loadReactionsForMoments(recent),
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryVaultStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<MemorySummary?> savePromptDay(
    CreateMemoryFromPromptInput input,
  ) async {
    emit(state.copyWith(status: MemoryVaultStatus.saving, clearError: true));
    final result = await _memories.createFromPromptResponses(input);

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: MemoryVaultStatus.loaded,
            memories: [value, ...state.memories],
          ),
        );
        return value;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryVaultStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return null;
    }
  }

  Future<MemorySummary?> createAdvanced(CreateAdvancedMemoryInput input) async {
    emit(state.copyWith(status: MemoryVaultStatus.saving, clearError: true));
    final result = await _memories.createAdvancedMemory(input);

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: MemoryVaultStatus.loaded,
            memories: [value, ...state.memories],
          ),
        );
        return value;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryVaultStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return null;
    }
  }

  Future<bool> deleteMemory(String memoryId) async {
    emit(state.copyWith(status: MemoryVaultStatus.saving, clearError: true));
    final result = await _memories.deleteMemory(memoryId);

    switch (result) {
      case Success():
        emit(
          state.copyWith(
            status: MemoryVaultStatus.loaded,
            memories: state.memories.where((m) => m.id != memoryId).toList(),
          ),
        );
        return true;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryVaultStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return false;
    }
  }

  Future<bool> dismissRecentMoment(
    Moment moment, {
    required bool isSender,
  }) async {
    emit(state.copyWith(status: MemoryVaultStatus.saving, clearError: true));

    final result = isSender
        ? await _moments.deleteSentMoment(moment.id)
        : await _moments.removeFromFeed(moment.id);

    switch (result) {
      case Success():
        final remaining = state.recentMoments
            .where((item) => item.id != moment.id)
            .toList();
        emit(
          state.copyWith(
            status: MemoryVaultStatus.loaded,
            recentMoments: remaining,
            dailyCategories: _categoriesFor(remaining),
            reactionsByMomentId: Map<String, MomentReactionSummary>.from(
              state.reactionsByMomentId,
            )..remove(moment.id),
          ),
        );
        return true;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryVaultStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return false;
    }
  }

  Future<MemorySummary?> saveMomentToVault(Moment moment) async {
    emit(state.copyWith(status: MemoryVaultStatus.saving, clearError: true));

    final caption = moment.caption?.trim();
    final title = caption != null && caption.isNotEmpty
        ? (caption.length > 48 ? '${caption.substring(0, 48)}…' : caption)
        : 'Moment with ${moment.sender.displayName}';

    final createResult = await _memories.createAdvancedMemory(
      CreateAdvancedMemoryInput(
        title: title,
        memoryType: MemoryType.custom,
        caption: caption,
        memoryDate: moment.createdAt,
      ),
    );

    switch (createResult) {
      case Success(:final value):
        final created = value;
        final updateResult = await _memories.updateMemory(
          UpdateMemoryInput(
            memoryId: created.id,
            title: created.title,
            caption: created.caption,
            coverMomentId: moment.id,
          ),
        );
        switch (updateResult) {
          case Success(:final value):
            emit(
              state.copyWith(
                status: MemoryVaultStatus.loaded,
                memories: [
                  value,
                  ...state.memories.where((m) => m.id != value.id),
                ],
              ),
            );
            return value;
          case Failed(:final failure):
            emit(
              state.copyWith(
                status: MemoryVaultStatus.loaded,
                memories: [created, ...state.memories],
                errorMessage: failure.message,
              ),
            );
            return created;
        }
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryVaultStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return null;
    }
  }

  Future<List<Moment>> _loadCameraRollMoments() async {
    final results = await Future.wait([
      _moments.listSentMoments(limit: 60),
      _moments.listReceivedMoments(
        limit: 60,
        seenFilter: MomentSeenFilter.all,
      ),
    ]);

    final byId = <String, Moment>{};
    for (final result in results) {
      final moments = switch (result) {
        Success(:final value) => value,
        Failed() => const <Moment>[],
      };
      for (final moment in moments) {
        byId[moment.id] = moment;
      }
    }

    return byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _loadCircleMembership() async {
    final circlesResult = await _circles.getMyCircles();
    final circles = switch (circlesResult) {
      Success(:final value) => value,
      Failed() => const <Circle>[],
    };
    final members = <String, List<UserProfile>>{};
    for (final circle in circles) {
      final result = await _circles.getCircleMembers(circle.id);
      members[circle.id] = switch (result) {
        Success(:final value) => value.map((member) => member.profile).toList(),
        Failed() => const <UserProfile>[],
      };
    }
    _cachedCircles = circles;
    _cachedMembers = members;
  }

  List<DailyCategory> _categoriesFor(List<Moment> moments) {
    return buildDailyCategories(
      moments: moments,
      circles: _cachedCircles,
      membersByCircle: _cachedMembers,
    );
  }

  Future<Map<String, MomentReactionSummary>> _loadReactionsForMoments(
    List<Moment> moments,
  ) async {
    final reactions = <String, MomentReactionSummary>{};
    await Future.wait(
      moments.map((moment) async {
        final result = await _social.getReactionSummary(moment.id);
        if (result case Success(:final value)) {
          reactions[moment.id] = value;
        }
      }),
    );
    return reactions;
  }
}

enum MemoryDetailStatus { initial, loading, loaded, deleting, saving, failure }

class MemoryDetailState extends Equatable {
  const MemoryDetailState({
    this.status = MemoryDetailStatus.initial,
    this.detail,
    this.errorMessage,
    this.savedMessage,
  });

  final MemoryDetailStatus status;
  final MemoryDetail? detail;
  final String? errorMessage;
  final String? savedMessage;

  MemoryDetailState copyWith({
    MemoryDetailStatus? status,
    MemoryDetail? detail,
    String? errorMessage,
    String? savedMessage,
    bool clearMessages = false,
  }) {
    return MemoryDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      savedMessage: clearMessages ? null : savedMessage ?? this.savedMessage,
    );
  }

  @override
  List<Object?> get props => [status, detail, errorMessage, savedMessage];
}

class MemoryDetailCubit extends Cubit<MemoryDetailState> {
  MemoryDetailCubit(this._memories, this._memoryId)
    : super(const MemoryDetailState());

  final MemoryRepository _memories;
  final String _memoryId;

  Future<void> load() async {
    emit(
      state.copyWith(status: MemoryDetailStatus.loading, clearMessages: true),
    );
    final result = await _memories.getMemory(_memoryId);

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(status: MemoryDetailStatus.loaded, detail: value));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryDetailStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<bool> deleteMemory() async {
    emit(
      state.copyWith(status: MemoryDetailStatus.deleting, clearMessages: true),
    );
    final result = await _memories.deleteMemory(_memoryId);

    switch (result) {
      case Success():
        return true;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryDetailStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return false;
    }
  }

  Future<void> updateMemory(UpdateMemoryInput input) async {
    emit(
      state.copyWith(status: MemoryDetailStatus.saving, clearMessages: true),
    );
    final result = await _memories.updateMemory(input);

    switch (result) {
      case Success():
        await load();
        emit(state.copyWith(savedMessage: 'Memory updated.'));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryDetailStatus.loaded,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> uploadCover(Uint8List bytes, String mimeType) async {
    emit(
      state.copyWith(status: MemoryDetailStatus.saving, clearMessages: true),
    );
    final result = await _memories.uploadCover(
      memoryId: _memoryId,
      bytes: bytes,
      mimeType: mimeType,
    );

    switch (result) {
      case Success():
        await load();
        emit(state.copyWith(savedMessage: 'Cover updated.'));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryDetailStatus.loaded,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> addChapter(String title) async {
    final detail = state.detail;
    if (detail == null) return;

    emit(
      state.copyWith(status: MemoryDetailStatus.saving, clearMessages: true),
    );
    final result = await _memories.upsertChapter(
      UpsertMemoryChapterInput(
        memoryId: _memoryId,
        title: title,
        position: detail.chapters.length,
      ),
    );

    switch (result) {
      case Success():
        await load();
        emit(state.copyWith(savedMessage: 'Chapter added.'));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryDetailStatus.loaded,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> deleteChapter(String chapterId) async {
    emit(
      state.copyWith(status: MemoryDetailStatus.saving, clearMessages: true),
    );
    final result = await _memories.deleteChapter(chapterId);

    switch (result) {
      case Success():
        await load();
        emit(state.copyWith(savedMessage: 'Chapter removed.'));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryDetailStatus.loaded,
            errorMessage: failure.message,
          ),
        );
    }
  }
}

enum MemoryEditStatus { initial, loading, loaded, saving, failure }

class MemoryEditState extends Equatable {
  const MemoryEditState({
    this.status = MemoryEditStatus.initial,
    this.detail,
    this.catalog,
    this.circles = const [],
    this.errorMessage,
  });

  final MemoryEditStatus status;
  final MemoryDetail? detail;
  final MemoryThemeCatalog? catalog;
  final List<Circle> circles;
  final String? errorMessage;

  MemoryEditState copyWith({
    MemoryEditStatus? status,
    MemoryDetail? detail,
    MemoryThemeCatalog? catalog,
    List<Circle>? circles,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MemoryEditState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      catalog: catalog ?? this.catalog,
      circles: circles ?? this.circles,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, detail, catalog, circles, errorMessage];
}

class MemoryEditCubit extends Cubit<MemoryEditState> {
  MemoryEditCubit(this._memories, this._circles, this._memoryId)
    : super(const MemoryEditState());

  final MemoryRepository _memories;
  final CircleRepository _circles;
  final String _memoryId;

  Future<void> load() async {
    emit(state.copyWith(status: MemoryEditStatus.loading, clearError: true));

    final detailResult = await _memories.getMemory(_memoryId);
    final catalogResult = await _memories.getThemeCatalog();
    final circlesResult = await _circles.getMyCircles();

    switch (detailResult) {
      case Success(:final value):
        final catalog = switch (catalogResult) {
          Success(:final value) => value,
          Failed() => null,
        };
        final circles = switch (circlesResult) {
          Success(:final value) => value,
          Failed() => const <Circle>[],
        };
        emit(
          MemoryEditState(
            status: MemoryEditStatus.loaded,
            detail: value,
            catalog: catalog,
            circles: circles,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryEditStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<bool> save(UpdateMemoryInput input) async {
    emit(state.copyWith(status: MemoryEditStatus.saving, clearError: true));
    final result = await _memories.updateMemory(input);

    switch (result) {
      case Success():
        return true;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryEditStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return false;
    }
  }

  Future<void> uploadCover(Uint8List bytes, String mimeType) async {
    emit(state.copyWith(status: MemoryEditStatus.saving, clearError: true));
    final result = await _memories.uploadCover(
      memoryId: _memoryId,
      bytes: bytes,
      mimeType: mimeType,
    );

    switch (result) {
      case Success():
        await load();
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MemoryEditStatus.loaded,
            errorMessage: failure.message,
          ),
        );
    }
  }
}

enum CreateMemoryStatus { initial, loading, loaded, saving, failure }

class CreateMemoryState extends Equatable {
  const CreateMemoryState({
    this.status = CreateMemoryStatus.initial,
    this.catalog,
    this.circles = const [],
    this.errorMessage,
  });

  final CreateMemoryStatus status;
  final MemoryThemeCatalog? catalog;
  final List<Circle> circles;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, catalog, circles, errorMessage];
}

class CreateMemoryCubit extends Cubit<CreateMemoryState> {
  CreateMemoryCubit(this._memories, this._circles)
    : super(const CreateMemoryState());

  final MemoryRepository _memories;
  final CircleRepository _circles;

  Future<void> load() async {
    emit(const CreateMemoryState(status: CreateMemoryStatus.loading));

    final catalogResult = await _memories.getThemeCatalog();
    final circlesResult = await _circles.getMyCircles();

    final catalog = switch (catalogResult) {
      Success(:final value) => value,
      Failed(:final failure) => null,
    };
    final circles = switch (circlesResult) {
      Success(:final value) => value,
      Failed() => const <Circle>[],
    };

    if (catalogResult case Failed(:final failure)) {
      emit(
        CreateMemoryState(
          status: CreateMemoryStatus.failure,
          errorMessage: failure.message,
        ),
      );
      return;
    }

    emit(
      CreateMemoryState(
        status: CreateMemoryStatus.loaded,
        catalog: catalog,
        circles: circles,
      ),
    );
  }

  Future<MemorySummary?> create(CreateAdvancedMemoryInput input) async {
    final catalog = state.catalog;
    final circles = state.circles;
    emit(
      CreateMemoryState(
        status: CreateMemoryStatus.saving,
        catalog: catalog,
        circles: circles,
      ),
    );
    final result = await _memories.createAdvancedMemory(input);

    switch (result) {
      case Success(:final value):
        emit(
          CreateMemoryState(
            status: CreateMemoryStatus.loaded,
            catalog: catalog,
            circles: circles,
          ),
        );
        return value;
      case Failed(:final failure):
        emit(
          CreateMemoryState(
            status: CreateMemoryStatus.loaded,
            catalog: catalog,
            circles: circles,
            errorMessage: failure.message,
          ),
        );
        return null;
    }
  }
}
