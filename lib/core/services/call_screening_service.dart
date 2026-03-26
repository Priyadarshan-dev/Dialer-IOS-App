import 'package:flutter/services.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';

/// Simplified CallScreeningService.
/// On Android, the native side now reads directly from SharedPreferences.
/// The Flutter side only needs to handle the sync request if needed.
class CallScreeningService {
  static const MethodChannel _channel = MethodChannel(AppConstants.callScreeningChannel);

  /// Initializes the Method Channel handlers for Android Call Screening.
  static Future<void> initializeCallScreening() async {
    _channel.setMethodCallHandler((call) async {
      // The native side now handles getCallNotes internally via SharedPreferences.
      // We keep this here in case we want to trigger a full re-sync from native.
      if (call.method == AppConstants.getCallNotesMethod) {
          // No longer needed to query Hive from here.
          return null;
      }
      return null;
    });
  }

  /// Triggers a sync/reload notification on the native side if necessary.
  static Future<void> syncCallDirectory() async {
    try {
      await _channel.invokeMethod(AppConstants.syncCallDirectoryMethod);
    } on PlatformException catch (e) {
      print('[DEBUG] CallScreeningService: Sync notification failed: ${e.message}');
    }
  }
}
