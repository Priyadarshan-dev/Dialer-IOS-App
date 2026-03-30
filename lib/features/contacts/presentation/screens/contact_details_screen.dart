import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:uuid/uuid.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/providers.dart';
import 'package:dialer_app_poc/features/contacts/presentation/screens/add_app_contact_screen.dart';

class ContactDetailsScreen extends ConsumerWidget {
  final dynamic contact;

  const ContactDetailsScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch relevant contacts state to reflect changes instantly
    final state = ref.watch(contactsProvider);
    
    // Find the latest version of the contact from our live state
    // We filter by ID since name or phone could have changed
    final latestContact = state.contacts.any((c) => c.id == contact.id)
        ? state.contacts.firstWhere((c) => c.id == contact.id)
        : contact;

    final name = latestContact.displayName;
    final phone = latestContact.phoneNumbers.isNotEmpty ? latestContact.phoneNumbers.first : 'No number';
    final initials = name.isNotEmpty 
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leadingWidth: 100,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(
            children: [
              Icon(Icons.arrow_back_ios, size: 22),
              Text('Contacts', style: TextStyle(fontSize: 17)),
            ],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          CupertinoButton(
            child: const Text('Edit', style: TextStyle(fontSize: 17)),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => AddAppContactScreen(existingContact: latestContact),
                  fullscreenDialog: true,
                ),
              ).then((_) => ref.read(contactsProvider.notifier).loadContacts());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Profile Initials
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF8E8E93),
              child: initials.isNotEmpty 
                ? Text(
                    initials,
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w500),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),
            
            // Call Action Card
            _buildSectionCard(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (phone != 'No number') {
                      final callHistory = CallHistoryEntity(
                        id: const Uuid().v4(),
                        contactName: name,
                        phoneNumber: phone,
                        callTime: DateTime.now(),
                        status: AppConstants.statusPending,
                      );
                      await ref.read(callHistoryProvider.notifier).saveCall(callHistory);
                      await FlutterPhoneDirectCaller.callNumber(phone);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Call', style: TextStyle(color: Colors.white, fontSize: 17)),
                        Icon(Icons.call, color: Color(0xFF34C759), size: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Info Cards
            _buildSectionCard(
              title: 'phone',
              children: [
                Text(
                  phone.startsWith('+') ? phone : '+91 $phone',
                  style: const TextStyle(color: Color(0xFF007AFF), fontSize: 17),
                ),
              ],
            ),
            

            // Delete Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Delete Contact', style: TextStyle(color: Color(0xFFFF3B30), fontSize: 17)),
                  ),
                ),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({String? title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.normal)),
            const SizedBox(height: 4),
          ],
          ...children,
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Delete Contact'),
        message: const Text('Are you sure you want to delete this contact?'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              // Delete logic
              await ref.read(contactsProvider.notifier).deleteAppContact(contact.id);
              if (context.mounted) {
                Navigator.pop(context); // Close sheet
                Navigator.pop(context); // Back to Contacts
              }
            },
            child: const Text('Delete Contact'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
