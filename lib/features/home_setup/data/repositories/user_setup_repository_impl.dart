import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/home_setup/data/datasources/user_setup_remote_data_source.dart';
import 'package:moment/features/home_setup/domain/entities/user_setup_metadata.dart';
import 'package:moment/features/home_setup/domain/repositories/user_setup_repository.dart';

class UserSetupRepositoryImpl implements UserSetupRepository {
  UserSetupRepositoryImpl(this._remote, this._userIdProvider);

  final UserSetupRemoteDataSource _remote;
  final String? Function() _userIdProvider;

  String? get _userId => _userIdProvider();

  @override
  Future<Result<UserSetupMetadata>> getMetadata() async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.fetchOrCreate(userId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> markWidgetReminderShown(DateTime shownAt) async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.update(userId, {
        'widget_reminder_last_shown_at': shownAt.toUtc().toIso8601String(),
      });
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> recordWidgetReminderDismissed() async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      final current = await _remote.fetchOrCreate(userId);
      await _remote.update(userId, {
        'widget_reminder_dismissed_count':
            current.widgetReminderDismissedCount + 1,
        'widget_reminder_last_shown_at': DateTime.now().toUtc().toIso8601String(),
      });
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<void>> markWidgetSetupConfirmed() async {
    final userId = _userId;
    if (userId == null) return const Failed(AuthenticationFailure());

    try {
      await _remote.update(userId, {'widget_setup_confirmed': true});
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }
}
