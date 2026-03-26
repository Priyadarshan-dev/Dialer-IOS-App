import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dialer_app_poc/providers.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/features/call_history/presentation/screens/widgets/call_history_tile.dart';
import 'package:dialer_app_poc/features/call_history/presentation/screens/widgets/notes_popup_dialog.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(callHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Call History'),
        surfaceTintColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: () => ref.read(callHistoryProvider.notifier).loadCalls(),
        child: _buildList(context, ref, state.calls),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<CallHistoryEntity> calls) {
    if (calls.isEmpty) {
      return const Center(child: Text('No call history.'));
    }

    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        return CallHistoryTile(
          call: call,
          onEdit: () => _showEditDialog(context, call),
          onDelete: () => _showDeleteDialog(context, ref, call),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, CallHistoryEntity call) {
    showDialog(
      context: context,
      builder: (context) => NotesPopupDialog(call: call, isEdit: true),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, CallHistoryEntity call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Call'),
        content: const Text('Are you sure you want to delete this call record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(callHistoryProvider.notifier).deleteCall(call.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
