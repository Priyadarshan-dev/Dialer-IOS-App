import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dialer_app_poc/providers.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:uuid/uuid.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/features/call_history/presentation/screens/widgets/call_history_tile.dart';
import 'package:dialer_app_poc/features/call_history/presentation/screens/recent_details_screen.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callHistoryProvider);
    
    final filteredCalls = state.calls;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recents',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF38383A), height: 1, indent: 16),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF007AFF),
                backgroundColor: const Color(0xFF1C1C1E),
                onRefresh: () => ref.read(callHistoryProvider.notifier).loadCalls(),
                child: _buildList(context, ref, filteredCalls),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<CallHistoryEntity> calls) {
    if (calls.isEmpty) {
      return ListView( // To allow pull-to-refresh
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Center(child: Text('No call history.', style: TextStyle(color: Color(0xFF8E8E93)))),
        ],
      );
    }

    // Grouping Logic
    final Map<String, List<CallHistoryEntity>> groupedMap = {};
    for (var call in calls) {
      groupedMap.putIfAbsent(call.phoneNumber, () => []).add(call);
    }

    // Convert map to a list of groups, sorted by the latest call in each group
    final List<List<CallHistoryEntity>> groupedList = groupedMap.values.toList()
      ..sort((a, b) => b.first.callTime.compareTo(a.first.callTime));

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: groupedList.length,
      itemBuilder: (context, index) {
        final group = groupedList[index];
        final latestCall = group.first;
        final count = group.length;

        // Find the latest non-empty note in the group
        String? latestNote;
        for (var c in group) {
          if (c.notes != null && c.notes!.isNotEmpty) {
            latestNote = c.notes;
            break; // Since the group is sorted by time, the first non-empty note is the latest
          }
        }

        return CallHistoryTile(
          call: latestCall.copyWith(notes: latestNote),
          count: count,
          onEdit: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => RecentDetailsScreen(
                  calls: group,
                ),
              ),
            );
          },
          onCall: () async {
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
          onDelete: () {
            _showDeleteConfirmation(context, ref, group);
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, List<CallHistoryEntity> group) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Delete History'),
        message: const Text('Deleting this history will also clear all saved notes for this contact.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              final ids = group.map((c) => c.id).toList();
              final phoneNumber = group.first.phoneNumber;
              ref.read(callHistoryProvider.notifier).deleteCalls(ids, phoneNumber);
              Navigator.pop(context);
            },
            child: const Text('Delete History'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
