import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/subscription/domain/entities/subscription.dart';
import 'package:moment/features/subscription/domain/repositories/subscription_repository.dart';

enum PremiumStatus { initial, loading, loaded, checkingOut, failure }

class PremiumState extends Equatable {
  const PremiumState({
    this.status = PremiumStatus.initial,
    this.offering,
    this.selectedPlanId,
    this.errorMessage,
    this.checkoutMessage,
  });

  final PremiumStatus status;
  final MomentPlusOffering? offering;
  final String? selectedPlanId;
  final String? errorMessage;
  final String? checkoutMessage;

  PremiumState copyWith({
    PremiumStatus? status,
    MomentPlusOffering? offering,
    String? selectedPlanId,
    String? errorMessage,
    String? checkoutMessage,
    bool clearMessages = false,
  }) {
    return PremiumState(
      status: status ?? this.status,
      offering: offering ?? this.offering,
      selectedPlanId: selectedPlanId ?? this.selectedPlanId,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      checkoutMessage: clearMessages
          ? null
          : checkoutMessage ?? this.checkoutMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    offering,
    selectedPlanId,
    errorMessage,
    checkoutMessage,
  ];
}

class PremiumCubit extends Cubit<PremiumState> {
  PremiumCubit(this._repository) : super(const PremiumState());

  final SubscriptionRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: PremiumStatus.loading, clearMessages: true));
    final result = await _repository.getOffering();

    switch (result) {
      case Success(:final value):
        final monthly = value.plans
            .where((p) => p.interval == BillingInterval.month)
            .firstOrNull;
        emit(
          state.copyWith(
            status: PremiumStatus.loaded,
            offering: value,
            selectedPlanId: monthly?.id ??
                (value.plans.isNotEmpty ? value.plans.first.id : null),
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: PremiumStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  void selectPlan(String planId) {
    emit(state.copyWith(selectedPlanId: planId));
  }

  Future<void> subscribe() async {
    final planId = state.selectedPlanId;
    if (planId == null) return;

    emit(
      state.copyWith(status: PremiumStatus.checkingOut, clearMessages: true),
    );
    final result = await _repository.requestCheckout(planId);

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: PremiumStatus.loaded,
            checkoutMessage: value.message,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: PremiumStatus.loaded,
            errorMessage: failure.message,
          ),
        );
    }
  }
}
