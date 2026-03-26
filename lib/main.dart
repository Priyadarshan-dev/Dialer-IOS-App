import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dialer_app_poc/app.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/data/models/call_history_model.dart';
import 'package:dialer_app_poc/core/services/notification_service.dart';
import 'package:dialer_app_poc/core/services/call_screening_service.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(CallHistoryModelAdapter());
  
  // Open Boxes
  await Hive.openBox<CallHistoryModel>(AppConstants.callHistoryBox);

  // Initialize Notifications
  await NotificationService().init();
  
  // Initialize Call Screening for Android
  if (Platform.isAndroid) {
    await CallScreeningService.initializeCallScreening();
  }
  
  runApp(
    const ProviderScope(
      child: CRMApp(),
    ),
  );
}
