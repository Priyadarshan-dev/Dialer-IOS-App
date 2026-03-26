import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dialer_app_poc/providers.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/core/utils/date_formatter.dart';

class NotesPopupDialog extends ConsumerStatefulWidget {
  final CallHistoryEntity call;
  final bool isEdit;

  const NotesPopupDialog({
    super.key,
    required this.call,
    required this.isEdit,
  });

  @override
  ConsumerState<NotesPopupDialog> createState() => _NotesPopupDialogState();
}

class _NotesPopupDialogState extends ConsumerState<NotesPopupDialog> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.call.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Text(
        widget.isEdit ? 'Edit Notes' : 'Call Summary',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1E293B)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 18, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.call.contactName,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.formatCallTime(widget.call.callTime),
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Notes',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Discussed pricing, follow up on Monday...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        if (!widget.isEdit)
          TextButton(
            onPressed: () {
              ref.read(callHistoryProvider.notifier).markCompleted(widget.call.id);
              Navigator.of(context).pop();
            },
            child: const Text('Skip', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          ),
        ElevatedButton(
          onPressed: () {
            ref.read(callHistoryProvider.notifier).updateNotes(widget.call.id, _notesController.text);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(widget.isEdit ? 'Save Changes' : 'Save & Finish', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
