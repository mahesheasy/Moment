import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/home_setup/domain/config/widget_reminder_config.dart';
import 'package:moment/features/home_setup/domain/entities/user_setup_metadata.dart';
import 'package:moment/features/home_setup/domain/services/widget_reminder_policy.dart';

void main() {
  const policy = WidgetReminderPolicy(
    WidgetReminderConfig(
      cooldowns: const [
        Duration(days: 7),
        Duration(days: 14),
        Duration(days: 30),
      ],
      maxHomeReminders: 3,
    ),
  );

  final base = DateTime.utc(2026, 1, 1, 12);

  group('WidgetReminderPolicy', () {
    test('shows when widget not confirmed and never shown', () {
      expect(
        policy.shouldShowOnHome(
          metadata: UserSetupMetadata.empty,
          now: base,
        ),
        isTrue,
      );
    });

    test('hides when widget confirmed', () {
      expect(
        policy.shouldShowOnHome(
          metadata: const UserSetupMetadata(
            widgetReminderDismissedCount: 0,
            widgetSetupConfirmed: true,
          ),
          now: base,
        ),
        isFalse,
      );
    });

    test('hides immediately after shown (before cooldown)', () {
      expect(
        policy.shouldShowOnHome(
          metadata: UserSetupMetadata(
            widgetReminderLastShownAt: base,
            widgetReminderDismissedCount: 0,
            widgetSetupConfirmed: false,
          ),
          now: base.add(const Duration(hours: 1)),
        ),
        isFalse,
      );
    });

    test('shows again after 7 day cooldown from first dismissal tier', () {
      expect(
        policy.shouldShowOnHome(
          metadata: UserSetupMetadata(
            widgetReminderLastShownAt: base,
            widgetReminderDismissedCount: 1,
            widgetSetupConfirmed: false,
          ),
          now: base.add(const Duration(days: 7, hours: 1)),
        ),
        isTrue,
      );
    });

    test('stops home reminders after max dismissals', () {
      expect(
        policy.shouldShowOnHome(
          metadata: UserSetupMetadata(
            widgetReminderLastShownAt: base.subtract(const Duration(days: 60)),
            widgetReminderDismissedCount: 3,
            widgetSetupConfirmed: false,
          ),
          now: base,
        ),
        isFalse,
      );
    });
  });
}
