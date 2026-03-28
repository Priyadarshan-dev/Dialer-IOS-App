import 'package:flutter/services.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/features/contacts/data/models/app_contact_model.dart';

import 'package:hive/hive.dart';
import 'package:dialer_app_poc/features/call_history/data/models/call_history_model.dart';

class CallDirectoryService {
  static const MethodChannel _channel = MethodChannel('com.liquid.dialer/call_directory');

  /// Synchronizes both call history notes and app-only contacts with the iOS Call Directory Extension.
  Future<void> syncAllData() async {
    try {
      final Map<String, String> data = {};

      // 1. Fetch App-Only Contacts
      final appContactsBox = Hive.box<AppContactModel>(AppConstants.appContactsBox);
      final Map<String, String> appNames = {};
      for (var contact in appContactsBox.values) {
        final rawDigits = _formatPhoneNumber(contact.phoneNumber);
        if (rawDigits.isNotEmpty) {
          appNames[rawDigits] = contact.name.trim();
        }
      }

      // 2. Fetch Call History Notes
      final historyBox = Hive.box<CallHistoryModel>(AppConstants.callHistoryBox);
      final Map<String, String> historyNotes = {};
      final sortedCalls = historyBox.values.toList()
        ..sort((a, b) => a.callTime.compareTo(b.callTime));
        
      for (var call in sortedCalls) {
        if (call.notes != null && call.notes!.trim().isNotEmpty) {
          final rawDigits = _formatPhoneNumber(call.phoneNumber);
          if (rawDigits.isNotEmpty) {
            historyNotes[rawDigits] = call.notes!.trim();
          }
        }
      }

      // 3. Combine them into the final data map
      final Set<String> allNumbers = {...appNames.keys, ...historyNotes.keys};
      for (var number in allNumbers) {
        final name = appNames[number];
        final note = historyNotes[number];
        
        String label = _truncateLabel(name, note);

        if (label.isNotEmpty) {
           data[number] = label;
           if (number.length == 10) {
             data['91$number'] = label;
           }
        }
      }

      if (data.isEmpty) {
        print('[DEBUG] CallDirectoryService: No data to sync.');
        return;
      }

      print('[DEBUG] CallDirectoryService: Syncing ${data.length} total entries to iOS...');
      await _channel.invokeMethod('syncAndReload', {
        'appGroupId': AppConstants.appGroupId,
        'fileName': AppConstants.callDirectoryFileName,
        'data': data,
      });
      
      print('[DEBUG] CallDirectoryService: Unified sync successful.');
    } on PlatformException catch (e) {
      print('[DEBUG] CallDirectoryService: Failed to sync data: ${e.message}');
    } catch (e) {
      print('[DEBUG] CallDirectoryService: Unexpected error during sync: $e');
    }
  }

  /// Formats the final label and truncates it to fit iOS CallKit limits (~45-50 chars).
  String _truncateLabel(String? name, String? note) {
    const int maxChars = 45;
    
    if (name != null && note != null) {
      final label = '$name — $note'; // Em-dash for natural reading
      if (label.length <= maxChars) return label;
      
      // If too long, keep the full name but truncate the note
      final availableForNote = maxChars - name.length - 4; // 4 for " — "
      if (availableForNote > 5) {
        return '$name — ${note.substring(0, availableForNote - 3)}...';
      } else {
        // Name itself is almost taking up the whole space
        return name.length > maxChars ? '${name.substring(0, maxChars - 3)}...' : name;
      }
    }
    
    final singleValue = name ?? note ?? '';
    if (singleValue.length <= maxChars) return singleValue;
    return '${singleValue.substring(0, maxChars - 3)}...';
  }

  /// Formats the phone number for CallKit.
  String _formatPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }
}
