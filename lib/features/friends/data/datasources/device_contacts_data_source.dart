import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:moment/features/friends/domain/entities/contact_suggestion.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceContactsDataSource {
  const DeviceContactsDataSource();

  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<List<ContactSuggestion>> loadContacts({int limit = 30}) async {
    final granted = await Permission.contacts.isGranted;
    if (!granted) return const [];

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    final suggestions = <ContactSuggestion>[];
    for (final contact in contacts) {
      final name = contact.displayName.trim();
      if (name.isEmpty) continue;

      String? phone;
      for (final phoneEntry in contact.phones) {
        final normalized = phoneEntry.number.replaceAll(RegExp(r'[^\d+]'), '');
        if (normalized.length >= 7) {
          phone = normalized;
          break;
        }
      }

      suggestions.add(
        ContactSuggestion(
          id: contact.id,
          displayName: name,
          phone: phone,
        ),
      );
      if (suggestions.length >= limit) break;
    }

    suggestions.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return suggestions;
  }
}
