import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/config/app_features.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/core/widget/android_widget_bridge.dart';
import 'package:moment/core/widget/widget_display_resolver.dart';
import 'package:moment/core/widget/widget_preview_stack_resolver.dart';
import 'package:moment/core/widgets/widget_moment_stack.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/circles/domain/repositories/circle_repository.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/moments/domain/repositories/moment_repository.dart';
import 'package:moment/features/widget_preferences/data/datasources/widget_preferences_local_cache.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';
import 'package:moment/features/widget_preferences/domain/repositories/widget_preferences_repository.dart';

enum WidgetCustomizationStatus { initial, loading, loaded, saving, failure }

class WidgetCustomizationState extends Equatable {
  const WidgetCustomizationState({
    this.status = WidgetCustomizationStatus.initial,
    this.bundle,
    this.draft,
    this.friends = const [],
    this.circles = const [],
    this.previewStackMoments = const [],
    this.previewStreakCount = 0,
    this.errorMessage,
    this.savedMessage,
  });

  final WidgetCustomizationStatus status;
  final WidgetPreferencesBundle? bundle;
  final WidgetPreferences? draft;
  final List<FriendSummary> friends;
  final List<Circle> circles;
  final List<WidgetStackPreviewMoment> previewStackMoments;
  final int previewStreakCount;
  final String? errorMessage;
  final String? savedMessage;

  bool get isPremium => bundle?.isPremium ?? false;

  /// True when the user can edit themes, accents, and content sources.
  bool get canCustomizeWidget =>
      isPremium || AppFeatures.momentPlusWidgetsUnlocked;

  WidgetCustomizationState copyWith({
    WidgetCustomizationStatus? status,
    WidgetPreferencesBundle? bundle,
    WidgetPreferences? draft,
    List<FriendSummary>? friends,
    List<Circle>? circles,
    List<WidgetStackPreviewMoment>? previewStackMoments,
    int? previewStreakCount,
    String? errorMessage,
    String? savedMessage,
    bool clearMessages = false,
  }) {
    return WidgetCustomizationState(
      status: status ?? this.status,
      bundle: bundle ?? this.bundle,
      draft: draft ?? this.draft,
      friends: friends ?? this.friends,
      circles: circles ?? this.circles,
      previewStackMoments: previewStackMoments ?? this.previewStackMoments,
      previewStreakCount: previewStreakCount ?? this.previewStreakCount,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      savedMessage: clearMessages ? null : savedMessage ?? this.savedMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    bundle,
    draft,
    friends,
    circles,
    previewStackMoments,
    previewStreakCount,
    errorMessage,
    savedMessage,
  ];
}

class WidgetCustomizationCubit extends Cubit<WidgetCustomizationState> {
  WidgetCustomizationCubit(
    this._preferences,
    this._friends,
    this._circles,
    this._moments,
    this._widgetBridge,
    this._localCache,
  ) : super(const WidgetCustomizationState());

  final WidgetPreferencesRepository _preferences;
  final FriendsRepository _friends;
  final CircleRepository _circles;
  final MomentRepository _moments;
  final AndroidWidgetBridge _widgetBridge;
  final WidgetPreferencesLocalCache _localCache;

  Timer? _deviceSyncDebounce;
  Timer? _privacyRemoteSaveDebounce;
  Timer? _previewRefreshDebounce;

  @override
  Future<void> close() {
    _deviceSyncDebounce?.cancel();
    _privacyRemoteSaveDebounce?.cancel();
    _previewRefreshDebounce?.cancel();
    return super.close();
  }

  Future<void> load() async {
    emit(
      state.copyWith(
        status: WidgetCustomizationStatus.loading,
        clearMessages: true,
      ),
    );

    final prefsResult = await _preferences.getPreferences();
    final friendsResult = await _friends.getFriends();
    final circlesResult = await _circles.getMyCircles();
    final draft = await _resolveDraft(prefsResult);

    final friends = switch (friendsResult) {
      Success(:final value) => value,
      Failed() => const <FriendSummary>[],
    };
    final circles = switch (circlesResult) {
      Success(:final value) => value,
      Failed() => const <Circle>[],
    };

    switch (prefsResult) {
      case Success(:final value):
        emit(
          WidgetCustomizationState(
            status: WidgetCustomizationStatus.loaded,
            bundle: value,
            draft: draft,
            friends: friends,
            circles: circles,
          ),
        );
        unawaited(_refreshPreviewStack(draft));
      case Failed():
        emit(
          WidgetCustomizationState(
            status: WidgetCustomizationStatus.loaded,
            bundle: WidgetPreferencesBundle(
              preferences: draft,
              isPremium: false,
              themes: WidgetTheme.relationshipThemes,
              typographyOptions: WidgetTypography.values,
              widgetModes: WidgetMode.values,
            ),
            draft: draft,
            friends: friends,
            circles: circles,
          ),
        );
        unawaited(_refreshPreviewStack(draft));
    }
  }

  void _schedulePreviewRefresh(WidgetPreferences draft) {
    _previewRefreshDebounce?.cancel();
    _previewRefreshDebounce = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(_refreshPreviewStack(draft)),
    );
  }

  Future<void> _refreshPreviewStack(WidgetPreferences draft) async {
    final loaded = await loadWidgetPreviewStack(
      moments: _moments,
      preferences: draft,
      circles: _circles,
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        previewStackMoments: loaded.stack,
        previewStreakCount: loaded.streakCount,
      ),
    );
  }

  Future<void> refreshPreviewStack() async {
    final draft = state.draft;
    if (draft == null) return;
    await _refreshPreviewStack(draft);
  }

  Future<WidgetPreferences> _resolveDraft(
    Result<WidgetPreferencesBundle> prefsResult,
  ) async {
    final remote = switch (prefsResult) {
      Success(:final value) =>
        (value.isPremium || AppFeatures.momentPlusWidgetsUnlocked) &&
                value.savedPreferences != null
            ? value.savedPreferences!
            : value.preferences,
      Failed() => WidgetPreferences.defaults(),
    };

    final local =
        await _localCache.read() ?? await _widgetBridge.readLocalPreferences();
    if (local == null) return remote;
    return remote.mergeLocal(local);
  }

  void setTheme(WidgetTheme theme) {
    final draft = state.draft;
    if (draft == null) return;
    final next = draft.copyWith(
      theme: theme,
      accentColor: theme.defaultAccent,
    );
    emit(state.copyWith(draft: next, clearMessages: true));
    _scheduleDeviceSync(next);
    _schedulePreviewRefresh(next);
  }

  void setTypography(WidgetTypography typography) {
    final draft = state.draft;
    if (draft == null) return;
    final next = draft.copyWith(typography: typography);
    emit(state.copyWith(draft: next, clearMessages: true));
    _scheduleDeviceSync(next);
  }

  void setAccentColor(String color) {
    final draft = state.draft;
    if (draft == null) return;
    final next = draft.copyWith(accentColor: color);
    emit(state.copyWith(draft: next, clearMessages: true));
    _scheduleDeviceSync(next);
  }

  void setDisplaySize(WidgetDisplaySize size) {
    final draft = state.draft;
    if (draft == null) return;
    final next = draft.copyWith(displaySize: size);
    emit(state.copyWith(draft: next, clearMessages: true));
    _scheduleDeviceSync(next);
  }

  void setWidgetMode(WidgetMode mode) {
    final draft = state.draft;
    if (draft == null) return;
    final next = draft.copyWith(
      widgetMode: mode,
      clearPerson: mode != WidgetMode.person,
      clearCircle: mode != WidgetMode.circle,
    );
    emit(state.copyWith(draft: next, clearMessages: true));
    _scheduleDeviceSync(next);
    _schedulePreviewRefresh(next);
  }

  void setSelectedPerson(String? personId) {
    final draft = state.draft;
    if (draft == null) return;
    final next = draft.copyWith(selectedPersonId: personId);
    emit(state.copyWith(draft: next, clearMessages: true));
    _scheduleDeviceSync(next);
    _schedulePreviewRefresh(next);
  }

  void setSelectedCircle(String? circleId) {
    final draft = state.draft;
    if (draft == null) return;
    final next = draft.copyWith(selectedCircleId: circleId);
    emit(state.copyWith(draft: next, clearMessages: true));
    _scheduleDeviceSync(next);
    _schedulePreviewRefresh(next);
  }

  void setPrivacyMode(WidgetPrivacyMode mode) {
    _patchPrivacy((draft) => draft.copyWith(privacyMode: mode));
  }

  void setPrivacyPerson(String? personId) {
    _patchPrivacy(
      (draft) => draft.copyWith(
        privacyPersonId: personId,
        clearPrivacyPerson: personId == null,
      ),
    );
  }

  void setShowSender(bool value) {
    _patchPrivacy((draft) => draft.copyWith(showSender: value));
  }

  void setShowTimestamp(bool value) {
    _patchPrivacy((draft) => draft.copyWith(showTimestamp: value));
  }

  void setShowCaptions(bool value) {
    _patchPrivacy((draft) => draft.copyWith(showCaptions: value));
  }

  void setLockScreenPrivacy(bool value) {
    _patchPrivacy((draft) => draft.copyWith(lockScreenPrivacy: value));
  }

  void setPaused(bool value) {
    _patchPrivacy((draft) => draft.copyWith(paused: value));
  }

  void setShowStreak(bool value) {
    final draft = state.draft;
    if (draft == null) return;
    final updated = draft.copyWith(showStreak: value);
    emit(state.copyWith(draft: updated));
    _scheduleDeviceSync(updated);
    unawaited(_localCache.save(updated));
  }

  void _patchPrivacy(WidgetPreferences Function(WidgetPreferences) update) {
    final draft = state.draft;
    if (draft == null) return;
    final next = update(draft);
    emit(state.copyWith(draft: next, clearMessages: true));
    _scheduleDeviceSync(next);
    _schedulePrivacyRemoteSave();
  }

  void _schedulePrivacyRemoteSave() {
    _privacyRemoteSaveDebounce?.cancel();
    _privacyRemoteSaveDebounce = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(savePrivacy(silent: true)),
    );
  }

  void _scheduleDeviceSync(WidgetPreferences draft) {
    if (!state.canCustomizeWidget) return;
    _deviceSyncDebounce?.cancel();
    _deviceSyncDebounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_persistAndSyncDevice(draft)),
    );
  }

  Future<void> _persistAndSyncDevice(WidgetPreferences draft) async {
    await _localCache.save(draft);
    final streakCount = switch (await _moments.getMomentStreak()) {
      Success(:final value) => value,
      Failed() => 0,
    };
    await _widgetBridge.syncPreferences(draft, streakCount: streakCount);
    await _syncWidgetMoments(draft);
    await _refreshPreviewStack(draft);
  }

  Future<void> _syncWidgetMoments(WidgetPreferences draft) async {
    final momentsResult = await _moments.getWidgetMoments(draft);
    if (momentsResult case Success(:final value) when value.isNotEmpty) {
      final titles = <String, String>{};
      for (final moment in value) {
        final display = await resolveWidgetDisplay(
          preferences: draft,
          moment: moment,
          circles: _circles,
        );
        titles[moment.id] = display.headerTitle;
      }
      await _widgetBridge.syncReceivedMoments(
        moments: value,
        preferences: draft,
        headerTitles: titles,
        headerEmoji: draft.theme.emoji,
      );
    }
  }

  Future<void> savePrivacy({bool silent = false}) async {
    final draft = state.draft;
    if (draft == null) return;

    emit(
      state.copyWith(
        status: silent
            ? WidgetCustomizationStatus.loaded
            : WidgetCustomizationStatus.saving,
        clearMessages: true,
      ),
    );

    await _localCache.save(draft);
    await _widgetBridge.syncPreferences(draft);
    await _syncWidgetMoments(draft);
    final result = await _preferences.savePrivacy(draft);
    switch (result) {
      case Success(:final value):
        final merged = await _resolveDraft(Success(value));
        emit(
          state.copyWith(
            status: WidgetCustomizationStatus.loaded,
            bundle: value,
            draft: merged,
            savedMessage: silent ? null : 'Privacy saved.',
          ),
        );
      case Failed():
        emit(
          state.copyWith(
            status: WidgetCustomizationStatus.loaded,
            draft: draft,
            savedMessage: silent ? null : 'Privacy saved on this device.',
          ),
        );
    }
  }

  Future<void> save() async {
    final draft = state.draft;
    if (draft == null) return;

    if (!state.canCustomizeWidget) {
      emit(
        state.copyWith(
          errorMessage: 'Upgrade to Moment+ to customize your widget.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: WidgetCustomizationStatus.saving,
        clearMessages: true,
      ),
    );

    await _localCache.save(draft);

    if (!state.isPremium && AppFeatures.momentPlusWidgetsUnlocked) {
      await _saveLocally(draft, remoteSync: false);
      return;
    }

    final result = await _preferences.savePreferences(draft);
    switch (result) {
      case Success(:final value):
        final bundle = value;
        await _saveLocally(draft, remoteSync: true, bundle: bundle);
      case Failed(:final failure):
        if (AppFeatures.momentPlusWidgetsUnlocked) {
          await _saveLocally(draft, remoteSync: false);
        } else {
          emit(
            state.copyWith(
              status: WidgetCustomizationStatus.loaded,
              errorMessage: failure.message,
            ),
          );
        }
    }
  }

  Future<void> _saveLocally(
    WidgetPreferences draft, {
    required bool remoteSync,
    WidgetPreferencesBundle? bundle,
  }) async {
    await _localCache.save(draft);
    await _widgetBridge.syncPreferences(draft);
    await _syncWidgetMoments(draft);
    emit(
      state.copyWith(
        status: WidgetCustomizationStatus.loaded,
        bundle: bundle ?? state.bundle,
        draft: draft,
        savedMessage: remoteSync
            ? 'Widget updated.'
            : 'Widget updated on this device.',
      ),
    );
  }
}
