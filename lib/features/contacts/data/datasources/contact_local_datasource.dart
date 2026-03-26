import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:dialer_app_poc/features/contacts/data/models/contact_model.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

abstract class ContactLocalDataSource {
  Future<List<ContactModel>> getContacts();
}

class ContactLocalDataSourceImpl implements ContactLocalDataSource {
  @override
  Future<List<ContactModel>> getContacts() async {
    print('[DEBUG] ContactLocalDataSource: Checking contacts permission...');

    // ✅ Use permission_handler to check status (already requested in app.dart)
    final status = await ph.Permission.contacts.status;
    print('[DEBUG] ContactLocalDataSource: Permission status: $status');

    if (status.isPermanentlyDenied) {
      print('[DEBUG] ContactLocalDataSource: Permission permanently denied.');
      throw Exception('Permission permanently denied. Please enable in settings.');
    }

    if (!status.isGranted) {
      print('[DEBUG] ContactLocalDataSource: Permission not granted: $status');
      throw Exception('Contacts permission denied. Please enable in settings.');
    }

    print('[DEBUG] ContactLocalDataSource: Permission granted. Fetching contacts...');

    // ✅ Directly fetch contacts with phone numbers — 2.0.1 defaults to only IDs/names
    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.phone},
    );

    print('[DEBUG] ContactLocalDataSource: Successfully fetched ${contacts.length} contacts');

    return contacts.map((c) {
      print('[DEBUG] Mapping contact: ${c.id}');
      return ContactModel.fromFlutterContact(c);
    }).toList();
  }
}

