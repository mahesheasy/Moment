import 'package:equatable/equatable.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';

class TimeTravelEntry extends Equatable {
  const TimeTravelEntry({
    required this.yearsAgo,
    required this.targetDate,
    this.moment,
  });

  final int yearsAgo;
  final DateTime targetDate;
  final Moment? moment;

  bool get hasMoment => moment != null;

  String get headline {
    return switch (yearsAgo) {
      1 => '1 YEAR AGO',
      _ => '$yearsAgo YEARS AGO',
    };
  }

  String get formattedDate {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final local = targetDate.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  @override
  List<Object?> get props => [yearsAgo, targetDate, moment];
}
