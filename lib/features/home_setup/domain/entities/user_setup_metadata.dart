import 'package:equatable/equatable.dart';

class UserSetupMetadata extends Equatable {
  const UserSetupMetadata({
    required this.widgetReminderDismissedCount,
    required this.widgetSetupConfirmed,
    this.widgetReminderLastShownAt,
  });

  final DateTime? widgetReminderLastShownAt;
  final int widgetReminderDismissedCount;
  final bool widgetSetupConfirmed;

  static const empty = UserSetupMetadata(
    widgetReminderDismissedCount: 0,
    widgetSetupConfirmed: false,
  );

  @override
  List<Object?> get props => [
    widgetReminderLastShownAt,
    widgetReminderDismissedCount,
    widgetSetupConfirmed,
  ];
}
