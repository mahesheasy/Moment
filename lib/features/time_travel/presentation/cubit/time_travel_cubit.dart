import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/time_travel/domain/entities/time_travel_entry.dart';
import 'package:moment/features/time_travel/domain/repositories/time_travel_repository.dart';

enum TimeTravelStatus { initial, loading, loaded, failure }

class TimeTravelState extends Equatable {
  const TimeTravelState({
    this.status = TimeTravelStatus.initial,
    this.entries = const [],
    this.errorMessage,
  });

  final TimeTravelStatus status;
  final List<TimeTravelEntry> entries;
  final String? errorMessage;

  TimeTravelState copyWith({
    TimeTravelStatus? status,
    List<TimeTravelEntry>? entries,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TimeTravelState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, entries, errorMessage];
}

class TimeTravelCubit extends Cubit<TimeTravelState> {
  TimeTravelCubit(this._repository) : super(const TimeTravelState());

  final TimeTravelRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: TimeTravelStatus.loading, clearError: true));
    final result = await _repository.getTimeTravelEntries();

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(status: TimeTravelStatus.loaded, entries: value));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: TimeTravelStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }
}
