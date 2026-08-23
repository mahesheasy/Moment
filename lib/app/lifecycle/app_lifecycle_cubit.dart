import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppLifecycleStateView extends Equatable {
  const AppLifecycleStateView(this.status);

  final AppLifecycleState status;

  @override
  List<Object?> get props => [status];
}

class AppLifecycleCubit extends Cubit<AppLifecycleStateView> {
  AppLifecycleCubit()
    : super(const AppLifecycleStateView(AppLifecycleState.resumed));

  void handle(AppLifecycleState state) {
    emit(AppLifecycleStateView(state));
  }
}

class AppLifecycleObserver with WidgetsBindingObserver {
  AppLifecycleObserver(this._cubit);

  final AppLifecycleCubit _cubit;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cubit.handle(state);
  }
}
