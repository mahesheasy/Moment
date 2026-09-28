/// Cooldown schedule after each "Maybe later" on the widget reminder.
class WidgetReminderConfig {
  const WidgetReminderConfig({
    this.cooldowns = const [
      Duration(days: 7),
      Duration(days: 14),
      Duration(days: 30),
    ],
    this.maxHomeReminders = 3,
  });

  final List<Duration> cooldowns;
  final int maxHomeReminders;

  Duration cooldownAfterDismissals(int dismissedCount) {
    if (dismissedCount <= 0) return cooldowns.first;
    final index = dismissedCount - 1;
    if (index >= cooldowns.length) {
      return cooldowns.last;
    }
    return cooldowns[index];
  }
}
