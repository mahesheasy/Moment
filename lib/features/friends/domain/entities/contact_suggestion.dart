import 'package:equatable/equatable.dart';

/// A device contact surfaced in friend discovery (invite or add on Moment).
class ContactSuggestion extends Equatable {
  const ContactSuggestion({
    required this.id,
    required this.displayName,
    this.phone,
  });

  final String id;
  final String displayName;
  final String? phone;

  @override
  List<Object?> get props => [id, displayName, phone];
}
