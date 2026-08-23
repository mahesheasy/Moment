import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/push/push_bridge.dart';
import 'package:moment/features/settings/data/datasources/notification_preferences_local_cache.dart';

enum NotificationSettingsStatus { initial, loading, loaded, saving }

class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.status = NotificationSettingsStatus.initial,
    this.preferences = const NotificationPreferences(),
  });

  final NotificationSettingsStatus status;
  final NotificationPreferences preferences;

  bool get isSaving => status == NotificationSettingsStatus.saving;

  NotificationSettingsState copyWith({
    NotificationSettingsStatus? status,
    NotificationPreferences? preferences,
  }) {
    return NotificationSettingsState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [status, preferences];
}

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit(this._cache, this._pushBridge)
      : super(const NotificationSettingsState());

  final NotificationPreferencesLocalCache _cache;
  final PushBridge _pushBridge;

  Future<void> load() async {
    emit(state.copyWith(status: NotificationSettingsStatus.loading));
    final preferences = await _cache.load();
    await _pushBridge.syncNotificationPreferences(preferences);
    emit(
      state.copyWith(
        status: NotificationSettingsStatus.loaded,
        preferences: preferences,
      ),
    );
  }

  Future<void> setPushEnabled(bool value) async {
    await _update(state.preferences.copyWith(pushEnabled: value));
  }

  Future<void> setMoments(bool value) async {
    await _update(state.preferences.copyWith(moments: value));
  }

  Future<void> setFriendRequests(bool value) async {
    await _update(state.preferences.copyWith(friendRequests: value));
  }

  Future<void> setMentions(bool value) async {
    await _update(state.preferences.copyWith(mentions: value));
  }

  Future<void> setMemories(bool value) async {
    await _update(state.preferences.copyWith(memories: value));
  }

  Future<void> setSecurity(bool value) async {
    await _update(state.preferences.copyWith(security: value));
  }

  Future<void> setEmailDigest(bool value) async {
    await _update(state.preferences.copyWith(emailDigest: value));
  }

  Future<void> _update(NotificationPreferences next) async {
    emit(
      state.copyWith(
        status: NotificationSettingsStatus.saving,
        preferences: next,
      ),
    );
    await _cache.save(next);
    await _pushBridge.syncNotificationPreferences(next);
    emit(
      state.copyWith(
        status: NotificationSettingsStatus.loaded,
        preferences: next,
      ),
    );
  }
}
