import 'package:flutter_contacts/flutter_contacts.dart';
import '../../domain/entities/contact_entity.dart';

class ContactModel {
  final String id;
  final String displayName;
  final List<String> phoneNumbers;
  final String? photoUrl;
  final bool isAppContact;

  ContactModel({
    required this.id,
    required this.displayName,
    required this.phoneNumbers,
    this.photoUrl,
    this.isAppContact = false,
  });

  factory ContactModel.fromFlutterContact(Contact contact) {
    return ContactModel(
      id: contact.id ?? '',
      displayName: contact.displayName ?? 'Unknown',
      phoneNumbers: contact.phones.map((p) => p.number).toList(),
      photoUrl: contact.photo != null ? 'has_photo' : null, // Not storing actual bytes here for simplicity
    );
  }

  ContactEntity toEntity() {
    return ContactEntity(
      id: id,
      displayName: displayName,
      phoneNumbers: phoneNumbers,
      photoUrl: photoUrl,
      isAppContact: isAppContact,
    );
  }
}
