import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/settings/domain/repositories/support_repository.dart';

enum ReportProblemStatus { initial, submitting, success, failure }

class ReportProblemState extends Equatable {
  const ReportProblemState({
    this.status = ReportProblemStatus.initial,
    this.errorMessage,
  });

  final ReportProblemStatus status;
  final String? errorMessage;

  bool get isSubmitting => status == ReportProblemStatus.submitting;

  ReportProblemState copyWith({
    ReportProblemStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportProblemState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}

class ReportProblemCubit extends Cubit<ReportProblemState> {
  ReportProblemCubit(this._repository) : super(const ReportProblemState());

  final SupportRepository _repository;

  Future<bool> submit({
    required String category,
    required String description,
  }) async {
    emit(
      state.copyWith(
        status: ReportProblemStatus.submitting,
        clearError: true,
      ),
    );

    final result = await _repository.submitReport(
      category: category,
      description: description,
    );

    switch (result) {
      case Success():
        emit(state.copyWith(status: ReportProblemStatus.success));
        return true;
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ReportProblemStatus.failure,
            errorMessage: failure.message,
          ),
        );
        return false;
    }
  }

  void reset() {
    emit(const ReportProblemState());
  }
}
