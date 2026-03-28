import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/features/call_history/presentation/screens/widgets/notes_popup_dialog.dart';
import 'package:dialer_app_poc/providers.dart';

class RecentDetailsScreen extends ConsumerWidget {
  final CallHistoryEntity call;

  const RecentDetailsScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat('h:mm a').format(call.callTime);
    final dateStr = _formatDate(call.callTime);
    final initials = call.contactName.isNotEmpty 
        ? call.contactName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
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
              Text('Recents', style: TextStyle(fontSize: 17)),
            ],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          CupertinoButton(
            child: const Text('Edit', style: TextStyle(fontSize: 17)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => NotesPopupDialog(call: call, isEdit: true),
              );
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
              call.contactName.isNotEmpty ? call.contactName : call.phoneNumber,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),
            
            // Call Action Card
            _buildSectionCard(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (call.phoneNumber.isNotEmpty) {
                      final callHistory = CallHistoryEntity(
                        id: const Uuid().v4(),
                        contactName: call.contactName,
                        phoneNumber: call.phoneNumber,
                        callTime: DateTime.now(),
                        status: AppConstants.statusPending,
                      );
                      await ref.read(callHistoryProvider.notifier).saveCall(callHistory);
                      await FlutterPhoneDirectCaller.callNumber(call.phoneNumber);
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
            
            // Call Info Card
            _buildSectionCard(
              children: [
                _buildInfoRow(dateStr, ''),
                _buildInfoRow(timeStr, 'Outgoing Call'),
              ],
            ),
            
            // Phone Number Card
            _buildSectionCard(
              children: [
                Row(
                  children: [
                    const Text('mobile', style: TextStyle(color: Colors.white, fontSize: 15)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3C),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('RECENT', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  call.phoneNumber.startsWith('+') ? call.phoneNumber : '+91 ${call.phoneNumber}',
                  style: const TextStyle(color: Color(0xFF007AFF), fontSize: 15),
                ),
              ],
            ),
            
            // Notes Card
            _buildSectionCard(
              title: 'Notes',
              children: [
                Text(
                  call.notes ?? 'No notes available.',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    return DateFormat('EEEE, MMM d').format(date);
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
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: const TextStyle(color: Colors.white, fontSize: 15)),
          Text(right, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15)),
        ],
      ),
    );
  }
}
