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
      backgroundColor: const Color(0xFF1C1C1E),
      surfaceTintColor: const Color(0xFF1C1C1E),
      title: Text(
        widget.isEdit ? 'Edit Notes' : 'Call Summary',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 18, color: Color(0xFF007AFF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.call.contactName,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF8E8E93)),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.formatCallTime(widget.call.callTime),
                        style: const TextStyle(color: Color(0xFF8E8E93)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Notes',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFEBEBF5)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Discussed pricing, follow up on Monday...',
                hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38383A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38383A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
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
            child: const Text('Skip', style: TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
          ),
        ElevatedButton(
          onPressed: () {
            ref.read(callHistoryProvider.notifier).updateNotes(widget.call.id, _notesController.text);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
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
