class AppConstants {
  static const String appName = 'Ronaldo';
  
  // Hive Box Names
  static const String callHistoryBox = 'call_history_box';
  static const String appContactsBox = 'app_contacts_box';
  
  // iOS Call Directory Constants
  static const String appGroupId = 'group.com.liquid.dialer.shared';
  static const String callDirectoryFileName = 'call_directory_data.json';
  static const String incomingCallLabelPrefix = 'NOTES';
  
  // Android Call Screening Constants
  static const String callScreeningChannel = 'com.liquid.dialer/call_screening';
  static const String getCallNotesMethod = 'getCallNotes';
  static const String syncCallDirectoryMethod = 'syncCallDirectory';
  
  // Permissions Strings
  static const String contactsPermissionDenied = 'Contacts permission is required to use this app.';
  static const String callPermissionDenied = 'Call permission is required to make calls.';
  
  // Call Status
  static const String statusPending = 'pending';
  static const String statusCompleted = 'completed';
}
