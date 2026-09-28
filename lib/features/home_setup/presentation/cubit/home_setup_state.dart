import 'package:equatable/equatable.dart';
import 'package:moment/features/home_setup/domain/entities/setup_requirement.dart';

enum HomeSetupStatus { initial, checking, ready, failed }

class HomeSetupState extends Equatable {
  const HomeSetupState({
    this.status = HomeSetupStatus.initial,
    this.requirement = SetupRequirement.none,
    this.acceptedFriendsCount,
    this.errorMessage,
    this.sheetVisible = false,
    this.checkedUserId,
  });

  final HomeSetupStatus status;
  final SetupRequirement requirement;
  final int? acceptedFriendsCount;
  final String? errorMessage;
  final bool sheetVisible;
  final String? checkedUserId;

  HomeSetupState copyWith({
    HomeSetupStatus? status,
    SetupRequirement? requirement,
    int? acceptedFriendsCount,
    String? errorMessage,
    bool? sheetVisible,
    String? checkedUserId,
    bool clearError = false,
    bool clearFriendsCount = false,
  }) {
    return HomeSetupState(
      status: status ?? this.status,
      requirement: requirement ?? this.requirement,
      acceptedFriendsCount: clearFriendsCount
          ? null
          : (acceptedFriendsCount ?? this.acceptedFriendsCount),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sheetVisible: sheetVisible ?? this.sheetVisible,
      checkedUserId: checkedUserId ?? this.checkedUserId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    requirement,
    acceptedFriendsCount,
    errorMessage,
    sheetVisible,
    checkedUserId,
  ];
}
