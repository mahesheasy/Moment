import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/auth/domain/username_suggestions.dart';
import 'package:moment/features/auth/domain/validators/auth_validators.dart';
import 'package:moment/features/profile/domain/usecases/profile_usecases.dart';

enum UsernameCheckStatus { idle, checking, available, taken, invalid, error }

class UsernameFieldState extends Equatable {
  const UsernameFieldState({
    this.status = UsernameCheckStatus.idle,
    this.username = '',
    this.suggestions = const [],
    this.hasTyped = false,
  });

  final UsernameCheckStatus status;
  final String username;
  final List<String> suggestions;
  final bool hasTyped;

  bool get isAvailable => status == UsernameCheckStatus.available;

  @override
  List<Object?> get props => [status, username, suggestions, hasTyped];
}

class UsernameFieldCubit extends Cubit<UsernameFieldState> {
  UsernameFieldCubit(this._checkAvailability) : super(const UsernameFieldState());

  final CheckUsernameAvailabilityUseCase _checkAvailability;
  Timer? _debounce;

  void reset() => emit(const UsernameFieldState());

  void onUsernameChanged({
    required String rawValue,
    required String displayName,
  }) {
    _debounce?.cancel();

    final normalized = AuthValidators.normalizeUsername(rawValue);
    final formatError = AuthValidators.validateUsername(rawValue);

    if (rawValue.trim().isEmpty) {
      emit(const UsernameFieldState());
      return;
    }

    if (formatError != null && normalized.length < 3) {
      emit(
        UsernameFieldState(
          status: UsernameCheckStatus.invalid,
          username: normalized,
          hasTyped: true,
        ),
      );
      return;
    }

    if (formatError != null) {
      emit(
        UsernameFieldState(
          status: UsernameCheckStatus.invalid,
          username: normalized,
          hasTyped: true,
        ),
      );
      return;
    }

    emit(
      UsernameFieldState(
        status: UsernameCheckStatus.checking,
        username: normalized,
        hasTyped: true,
      ),
    );

    _debounce = Timer(const Duration(milliseconds: 420), () {
      unawaited(_checkUsername(normalized, displayName));
    });
  }

  Future<void> applySuggestion(String username, String displayName) async {
    emit(
      UsernameFieldState(
        status: UsernameCheckStatus.checking,
        username: username,
        hasTyped: true,
      ),
    );
    await _checkUsername(username, displayName);
  }

  Future<void> recheck(String displayName) async {
    final username = state.username;
    if (username.isEmpty) return;
    emit(
      state.copyWith(status: UsernameCheckStatus.checking, clearSuggestions: true),
    );
    await _checkUsername(username, displayName);
  }

  Future<void> _checkUsername(String username, String displayName) async {
    final result = await _checkAvailability(username);
    if (!_isCurrentUsername(username)) return;

    switch (result) {
      case Success(:final value):
        if (value) {
          emit(
            UsernameFieldState(
              status: UsernameCheckStatus.available,
              username: username,
              hasTyped: true,
            ),
          );
        } else {
          final suggestions = await _availableSuggestions(
            displayName: displayName,
            typedUsername: username,
          );
          if (!_isCurrentUsername(username)) return;
          emit(
            UsernameFieldState(
              status: UsernameCheckStatus.taken,
              username: username,
              hasTyped: true,
              suggestions: suggestions,
            ),
          );
        }
      case Failed():
        emit(
          UsernameFieldState(
            status: UsernameCheckStatus.error,
            username: username,
            hasTyped: true,
          ),
        );
    }
  }

  bool _isCurrentUsername(String username) => state.username == username;

  /// Only return suggestions confirmed free in [profiles].
  Future<List<String>> _availableSuggestions({
    required String displayName,
    required String typedUsername,
  }) async {
    final pool = UsernameSuggestions.candidates(
      displayName: displayName,
      typedUsername: typedUsername,
    );
    final available = <String>[];

    for (final candidate in pool) {
      if (available.length >= 3) break;
      final result = await _checkAvailability(candidate);
      if (result case Success(:final value) when value) {
        available.add(candidate);
      }
    }

    return available;
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

extension on UsernameFieldState {
  UsernameFieldState copyWith({
    UsernameCheckStatus? status,
    String? username,
    List<String>? suggestions,
    bool? hasTyped,
    bool clearSuggestions = false,
  }) {
    return UsernameFieldState(
      status: status ?? this.status,
      username: username ?? this.username,
      suggestions: clearSuggestions
          ? const []
          : suggestions ?? this.suggestions,
      hasTyped: hasTyped ?? this.hasTyped,
    );
  }
}
