import 'package:moment/features/home_setup/domain/config/widget_reminder_config.dart';
import 'package:moment/features/home_setup/domain/entities/user_setup_metadata.dart';

class WidgetReminderPolicy {
  const WidgetReminderPolicy([this.config = const WidgetReminderConfig()]);

  final WidgetReminderConfig config;

  bool isWidgetConfigured(UserSetupMetadata metadata) {
    return metadata.widgetSetupConfirmed;
  }

  /// Whether the home screen should show the optional widget reminder.
  bool shouldShowOnHome({
    required UserSetupMetadata metadata,
    required DateTime now,
  }) {
    if (isWidgetConfigured(metadata)) return false;
    if (metadata.widgetReminderDismissedCount >= config.maxHomeReminders) {
      return false;
    }
    final lastShown = metadata.widgetReminderLastShownAt;
    if (lastShown == null) return true;

    final dismissed = metadata.widgetReminderDismissedCount;
    final cooldown = config.cooldownAfterDismissals(dismissed);
    return now.isAfter(lastShown.add(cooldown));
  }
}
