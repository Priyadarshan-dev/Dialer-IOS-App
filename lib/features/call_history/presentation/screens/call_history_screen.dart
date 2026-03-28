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

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        return CallHistoryTile(
          call: call,
          onEdit: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => RecentDetailsScreen(call: call)),
            );
          },
          onCall: () async {
            if (call.phoneNumber.isNotEmpty) {
              final newCallHistory = CallHistoryEntity(
                id: const Uuid().v4(),
                contactName: call.contactName,
                phoneNumber: call.phoneNumber,
                callTime: DateTime.now(),
                status: AppConstants.statusPending,
              );
              await ref.read(callHistoryProvider.notifier).saveCall(newCallHistory);
              await FlutterPhoneDirectCaller.callNumber(call.phoneNumber);
            }
          },
          onDelete: () {
            ref.read(callHistoryProvider.notifier).deleteCall(call.id);
          },
        );
      },
    );
  }
}
