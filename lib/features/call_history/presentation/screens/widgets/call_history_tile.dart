import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:intl/intl.dart';

class CallHistoryTile extends StatelessWidget {
  final CallHistoryEntity call;
  final VoidCallback onEdit;
  final VoidCallback onCall;
  final VoidCallback onDelete;

  const CallHistoryTile({
    super.key,
    required this.call,
    required this.onEdit,
    required this.onCall,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMissed = call.status == 'missed';
    final name = call.contactName.isNotEmpty ? call.contactName : call.phoneNumber;
    final timeStr = DateFormat('h:mm a').format(call.callTime);
    
    // Notes prefix logic matching User Request if notes exist
    final subtitle = (call.notes != null && call.notes!.isNotEmpty)
        ? 'Notes : ${call.notes}'
        : '';

    return Dismissible(
      key: Key(call.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDelete(),
      background: Container(
        color: const Color(0xFFFF3B30),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Text(
          'Delete',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Left Side: Name and Subtitle (trigger Call)
              Expanded(
                child: InkWell(
                  onTap: onCall,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isMissed ? Colors.red : Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              // Right Side: Time and Info Icon (trigger Edit/Details)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF007AFF),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF38383A), height: 1, indent: 16),
        ],
      ),
    );
  }
}
