import 'package:shared_preferences/shared_preferences.dart';

/// Service to sync call notes to SharedPreferences
/// This allows the Android Call Screening Service to access notes across processes
class SharedPreferencesService {
  static const String _noteKeyPrefix = 'notes_';

  /// Save note to SharedPreferences for Android Call Screening Service
  /// Key format: notes_{normalized_phone_number}
  /// Example: notes_919965205472
  static Future<void> saveNoteToSharedPrefs(String phoneNumber, String notes) async {
    try {
      print('[DEBUG] SharedPreferencesService: Saving note for $phoneNumber');
      
      final prefs = await SharedPreferences.getInstance();
      final normalized = _normalizePhoneNumber(phoneNumber);
      
      if (normalized.isEmpty) {
        print('[DEBUG] SharedPreferencesService: Normalized number is empty, skipping save');
        return;
      }
      
      final key = '$_noteKeyPrefix$normalized';
      print('[DEBUG] SharedPreferencesService: Key: $key');
      print('[DEBUG] SharedPreferencesService: Notes: $notes');
      
      // Save to SharedPreferences
      await prefs.setString(key, notes);
      
      // Verify it was saved
      final saved = prefs.getString(key);
      print('[DEBUG] SharedPreferencesService: Saved note for $normalized');
      print('[DEBUG] SharedPreferencesService: Verification - Data persisted: ${saved == notes}');
      
      // List all notes for debugging
      _debugListAllNotes(prefs);
      
    } catch (e) {
      print('[DEBUG] SharedPreferencesService: Error saving note: $e');
      rethrow;
    }
  }

  /// Get note from SharedPreferences
  static Future<String?> getNoteFromSharedPrefs(String phoneNumber) async {
    try {
      print('[DEBUG] SharedPreferencesService: Retrieving note for $phoneNumber');
      
      final prefs = await SharedPreferences.getInstance();
      final normalized = _normalizePhoneNumber(phoneNumber);
      
      if (normalized.isEmpty) {
        print('[DEBUG] SharedPreferencesService: Normalized number is empty');
        return null;
      }
      
      final key = '$_noteKeyPrefix$normalized';
      final note = prefs.getString(key);
      
      print('[DEBUG] SharedPreferencesService: Retrieved note for $normalized: $note');
      return note;
      
    } catch (e) {
      print('[DEBUG] SharedPreferencesService: Error retrieving note: $e');
      return null;
    }
  }

  /// Delete note from SharedPreferences
  static Future<void> deleteNoteFromSharedPrefs(String phoneNumber) async {
    try {
      print('[DEBUG] SharedPreferencesService: Deleting note for $phoneNumber');
      
      final prefs = await SharedPreferences.getInstance();
      final normalized = _normalizePhoneNumber(phoneNumber);
      
      if (normalized.isEmpty) {
        print('[DEBUG] SharedPreferencesService: Normalized number is empty, skipping delete');
        return;
      }
      
      final key = '$_noteKeyPrefix$normalized';
      await prefs.remove(key);
      
      print('[DEBUG] SharedPreferencesService: Deleted note for $normalized');
      
      // List remaining notes for debugging
      _debugListAllNotes(prefs);
      
    } catch (e) {
      print('[DEBUG] SharedPreferencesService: Error deleting note: $e');
      rethrow;
    }
  }

  /// Clear all notes from SharedPreferences
  static Future<void> clearAllNotes() async {
    try {
      print('[DEBUG] SharedPreferencesService: Clearing all notes...');
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_noteKeyPrefix)).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      print('[DEBUG] SharedPreferencesService: Cleared all notes (${keys.length} entries deleted)');
      
    } catch (e) {
      print('[DEBUG] SharedPreferencesService: Error clearing notes: $e');
      rethrow;
    }
  }

  /// Normalize phone number to match Kotlin normalization
  /// This MUST match the normalization in LiquidDialerCallScreeningService.kt
  ///
  /// Rules:
  /// 1. Remove all non-digit characters except leading +
  /// 2. If no leading +, remove leading zeros
  /// 3. For international numbers, keep digits after the +
  ///
  /// Examples:
  /// +91 99652 05472 → 919965205472
  /// 9965205472 → 9965205472
  /// +1-555-123-4567 → 15551234567
  static String _normalizePhoneNumber(String number) {
    if (number.isEmpty) {
      return '';
    }

    try {
      // Check if international format (starts with +)
      final isInternational = number.startsWith('+');

      // Step 1: Remove all non-digit characters except leading '+'
      var sanitized = number.replaceAll(RegExp(r'(?!^\+)\D'), '');

      // Step 2: Remove leading zeros if it's not an international format
      if (!sanitized.startsWith('+')) {
        sanitized = sanitized.replaceFirst(RegExp(r'^0+'), '');
      }

      // Step 3: For international numbers, keep the digits after the '+'
      if (sanitized.startsWith('+')) {
        sanitized = sanitized.substring(1);
      }

      return sanitized;
    } catch (e) {
      print('[DEBUG] SharedPreferencesService: Error normalizing phone number: $e');
      return number;
    }
  }

  /// Debug helper to list all saved notes in SharedPreferences
  static void _debugListAllNotes(SharedPreferences prefs) {
    final keys = prefs.getKeys().where((key) => key.startsWith(_noteKeyPrefix)).toList();
    print('[DEBUG] SharedPreferencesService: === All saved notes ===');
    
    if (keys.isEmpty) {
      print('[DEBUG] SharedPreferencesService: No notes saved yet');
    } else {
      print('[DEBUG] SharedPreferencesService: Total notes: ${keys.length}');
      for (final key in keys) {
        final value = prefs.getString(key);
        print('[DEBUG] SharedPreferencesService: $key = "$value"');
      }
    }
    
    print('[DEBUG] SharedPreferencesService: === End of notes ===');
  }
}