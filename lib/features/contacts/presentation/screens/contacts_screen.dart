import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:dialer_app_poc/providers.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/core/services/notification_service.dart';
import 'package:dialer_app_poc/features/contacts/presentation/screens/dialpad_screen.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contactsProvider);
    final notifier = ref.read(contactsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Contacts'),
        surfaceTintColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: TextStyle(color: const Color(0xFF94A3B8), fontSize: 16),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 24),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: notifier.searchContacts,
            ),
          ),
          Expanded(
            child: _buildBody(context, ref, state),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DialpadScreen()),
          );
        },
        backgroundColor: const Color(0xFF6366F1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.dialpad_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }
    
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFF43F5E)),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF475569), fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.read(contactsProvider.notifier).loadContacts(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No contacts found',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      onRefresh: () => ref.read(contactsProvider.notifier).loadContacts(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: state.filtered.length,
        itemBuilder: (context, index) {
          final contact = state.filtered[index];
          final name = contact.displayName;
          final phone = contact.phoneNumbers.isNotEmpty ? contact.phoneNumbers.first : 'No number';
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                title: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.call_rounded, color: Color(0xFF6366F1)),
                    onPressed: () => _handleCall(context, ref, contact),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleCall(BuildContext context, WidgetRef ref, contact) async {
    if (contact.phoneNumbers.isEmpty) return;

    final phoneNumber = contact.phoneNumbers.first;
    final callHistory = CallHistoryEntity(
      id: const Uuid().v4(),
      contactName: contact.displayName,
      phoneNumber: phoneNumber,
      callTime: DateTime.now(),
      status: AppConstants.statusPending,
    );

    // 1. Save pending call
    await ref.read(callHistoryProvider.notifier).saveCall(callHistory);

    // 2. Launch call
    print('[DEBUG] ContactsScreen: Initiating direct call to $phoneNumber');
    
    // On iOS, the app might be suspended immediately. Let's fire the notification 
    // slightly before or right after the call request without strictly waiting for 'res'.
    final res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    print('[DEBUG] ContactsScreen: Direct call result: $res');
    
    // 3. iOS Workaround: Show a persistent notification reminder
    // We check if res is true OR if we are on iOS (where res can sometimes be null/delayed)
    if (res == true || Platform.isIOS) {
       print('[DEBUG] ContactsScreen: Call initiated (res=$res), showing notification reminder');
       await NotificationService().showCallReminder(contact.displayName);
    }
    
    if (res == false && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not initiate direct call')),
      );
    }
  }
}
