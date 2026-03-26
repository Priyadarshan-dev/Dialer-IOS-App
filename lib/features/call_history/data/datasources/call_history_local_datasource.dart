import 'package:hive/hive.dart';
import 'package:dialer_app_poc/features/call_history/data/models/call_history_model.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';

abstract class CallHistoryLocalDataSource {
  Future<List<CallHistoryModel>> getAllCalls();
  Future<void> saveCall(CallHistoryModel call);
  Future<void> updateCallNotes(String id, String notes);
  Future<void> deleteCall(String id);
  Future<void> markCompleted(String id);
}

class CallHistoryLocalDataSourceImpl implements CallHistoryLocalDataSource {
  final Box<CallHistoryModel> callBox;

  CallHistoryLocalDataSourceImpl(this.callBox);

  @override
  Future<List<CallHistoryModel>> getAllCalls() async {
    return callBox.values.toList();
  }

  @override
  Future<void> saveCall(CallHistoryModel call) async {
    await callBox.put(call.id, call);
  }

  @override
  Future<void> updateCallNotes(String id, String notes) async {
    final call = callBox.get(id);
    if (call != null) {
      final updatedCall = CallHistoryModel(
        id: call.id,
        contactName: call.contactName,
        phoneNumber: call.phoneNumber,
        callTime: call.callTime,
        notes: notes,
        status: AppConstants.statusCompleted,
      );
      await callBox.put(id, updatedCall);
    }
  }

  @override
  Future<void> deleteCall(String id) async {
    await callBox.delete(id);
  }

  @override
  Future<void> markCompleted(String id) async {
    final call = callBox.get(id);
    if (call != null) {
      final updatedCall = CallHistoryModel(
        id: call.id,
        contactName: call.contactName,
        phoneNumber: call.phoneNumber,
        callTime: call.callTime,
        notes: call.notes,
        status: AppConstants.statusCompleted,
      );
      await callBox.put(id, updatedCall);
    }
  }
}
