import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:dialer_app_poc/features/contacts/data/models/contact_model.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:hive/hive.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/contacts/data/models/app_contact_model.dart';

abstract class ContactLocalDataSource {
  Future<List<ContactModel>> getContacts();
}

class ContactLocalDataSourceImpl implements ContactLocalDataSource {
  @override
  Future<List<ContactModel>> getContacts() async {
    // ======================================================================
    // NATIVE CONTACTS DISABLED (CRM Mode)
    // The app is acting as a CRM — only App-Only contacts (saved inside the
    // app) are shown. Native iOS address book contacts are hidden.
    // To re-enable native contacts, uncomment the block below.
    // ======================================================================

    // // Check permission
    // print('[DEBUG] ContactLocalDataSource: Checking contacts permission...');
    // final status = await ph.Permission.contacts.status;
    // print('[DEBUG] ContactLocalDataSource: Permission status: $status');
    // if (status.isPermanentlyDenied) {
    //   throw Exception('Permission permanently denied. Please enable in settings.');
    // }
    // if (!status.isGranted) {
    //   throw Exception('Contacts permission denied. Please enable in settings.');
    // }
    // print('[DEBUG] ContactLocalDataSource: Permission granted. Fetching contacts...');
    // final contacts = await FlutterContacts.getAll(
    //   properties: {ContactProperty.phone},
    // );
    // print('[DEBUG] ContactLocalDataSource: Successfully fetched \${contacts.length} contacts');
    // final nativeContacts = contacts.map((c) {
    //   return ContactModel.fromFlutterContact(c);
    // }).toList();

    // ✅ Fetch App-Only Contacts from Hive
    print('[DEBUG] ContactLocalDataSource: Fetching app contacts from Hive...');
    final appContactsBox = Hive.box<AppContactModel>(AppConstants.appContactsBox);
    final appContacts = appContactsBox.values.map((appContact) {
      return ContactModel(
        id: appContact.id,
        displayName: appContact.name,
        phoneNumbers: [appContact.phoneNumber],
        photoUrl: null,
        isAppContact: true,
      );
    }).toList();

    print('[DEBUG] ContactLocalDataSource: Fetched ${appContacts.length} app contacts');

    // Return only App-Only contacts (native disabled)
    // To re-enable native: return [...appContacts, ...nativeContacts];
    return appContacts;
  }
}
