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

class RecentDetailsScreen extends ConsumerStatefulWidget {
  final List<CallHistoryEntity> calls;

  const RecentDetailsScreen({super.key, required this.calls});

  @override
  ConsumerState<RecentDetailsScreen> createState() => _RecentDetailsScreenState();
}

class _RecentDetailsScreenState extends ConsumerState<RecentDetailsScreen> {
  bool _showAllNotes = false;

  @override
  Widget build(BuildContext context) {
    if (widget.calls.isEmpty) return const SizedBox.shrink();

    // Watch relevant call history state to reflect changes instantly
    final historyState = ref.watch(callHistoryProvider);
    
    // Get the phone number of the contact we're viewing
    final phoneNumber = widget.calls.first.phoneNumber;
    
    // Find the latest version of these calls from our live state
    final liveCalls = historyState.calls
        .where((c) => c.phoneNumber == phoneNumber)
        .toList()
      ..sort((a, b) => b.callTime.compareTo(a.callTime));
    
    // Use live data if found, or fall back to the initial list
    final currentCalls = liveCalls.isNotEmpty ? liveCalls : widget.calls;
    final latestCall = currentCalls.first;
    
    // Find the latest non-empty note to show at the top
    CallHistoryEntity? latestNoteCall;
    for (var c in currentCalls) {
      if (c.notes != null && c.notes!.isNotEmpty) {
        latestNoteCall = c;
        break;
      }
    }

    // Filter calls that have notes for the "Show More" section
    final pastNotesCalls = currentCalls.where((c) {
      if (latestNoteCall != null && c.id == latestNoteCall.id) return false;
      return c.notes != null && c.notes!.isNotEmpty;
    }).toList();

    final initials = latestCall.contactName.isNotEmpty 
        ? latestCall.contactName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
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
                builder: (context) => NotesPopupDialog(call: latestCall, isEdit: true),
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
              latestCall.contactName.isNotEmpty ? latestCall.contactName : latestCall.phoneNumber,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),
            
            // Call Action Card
            _buildSectionCard(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (latestCall.phoneNumber.isNotEmpty) {
                      final newCallHistory = CallHistoryEntity(
                        id: const Uuid().v4(),
                        contactName: latestCall.contactName,
                        phoneNumber: latestCall.phoneNumber,
                        callTime: DateTime.now(),
                        status: AppConstants.statusPending,
                      );
                      await ref.read(callHistoryProvider.notifier).saveCall(newCallHistory);
                      await FlutterPhoneDirectCaller.callNumber(latestCall.phoneNumber);
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
            
            // Recent Calls Info Card (showing details for the latest few calls)
            _buildSectionCard(
              children: currentCalls.take(3).map((c) => Column(
                children: [
                  _buildInfoRow(_formatDate(c.callTime), DateFormat('h:mm a').format(c.callTime)),
                  if (c != currentCalls.take(3).last) const Divider(color: Color(0xFF38383A), height: 12),
                ],
              )).toList(),
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
                  latestCall.phoneNumber.startsWith('+') ? latestCall.phoneNumber : '+91 ${latestCall.phoneNumber}',
                  style: const TextStyle(color: Color(0xFF007AFF), fontSize: 15),
                ),
              ],
            ),
            
            // Notes Card
            _buildSectionCard(
              title: 'Latest Note',
              children: [
                if (latestNoteCall != null) ...[
                  Text(
                    latestNoteCall.notes ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM d, h:mm a').format(latestNoteCall.callTime),
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                  ),
                ] else
                  const Text(
                    'No notes available.',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
                  ),
              ],
            ),

            // Past Notes (Show More logic)
            if (pastNotesCalls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (!_showAllNotes)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Show More Notes', style: TextStyle(color: Color(0xFF007AFF), fontSize: 15)),
                        onPressed: () => setState(() => _showAllNotes = true),
                      ),
                    if (_showAllNotes) ...[
                      const SizedBox(height: 10),
                      ...pastNotesCalls.map((c) => _buildSectionCard(
                        children: [
                          Text(
                            c.notes ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, h:mm a').format(c.callTime),
                            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                          ),
                        ],
                      )),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Show Less', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15)),
                        onPressed: () => setState(() => _showAllNotes = false),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 40),
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
