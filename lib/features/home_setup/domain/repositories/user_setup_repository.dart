import 'package:moment/core/result/result.dart';
import 'package:moment/features/home_setup/domain/entities/user_setup_metadata.dart';

abstract class UserSetupRepository {
  Future<Result<UserSetupMetadata>> getMetadata();

  Future<Result<void>> markWidgetReminderShown(DateTime shownAt);

  Future<Result<void>> recordWidgetReminderDismissed();

  Future<Result<void>> markWidgetSetupConfirmed();
}
