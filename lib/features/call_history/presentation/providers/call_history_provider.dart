import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dialer_app_poc/core/usecases/usecase.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/features/call_history/domain/usecases/call_history_usecases.dart';
import 'package:dialer_app_poc/features/call_history/presentation/states/call_history_state.dart';
import 'package:dialer_app_poc/core/services/call_directory_service.dart';
import 'package:dialer_app_poc/core/services/call_screening_service.dart';
import 'package:dialer_app_poc/core/services/shared_preferences_service.dart';
import 'dart:io';

class CallHistoryNotifier extends StateNotifier<CallHistoryState> {
  final GetAllCallsUseCase _getAllCallsUseCase;
  final SaveCallUseCase _saveCallUseCase;
  final UpdateCallNotesUseCase _updateCallNotesUseCase;
  final DeleteCallUseCase _deleteCallUseCase;
  final MarkCompletedUseCase _markCompletedUseCase;
  final CallDirectoryService _callDirectoryService;

  CallHistoryNotifier({
    required GetAllCallsUseCase getAllCallsUseCase,
    required SaveCallUseCase saveCallUseCase,
    required UpdateCallNotesUseCase updateCallNotesUseCase,
    required DeleteCallUseCase deleteCallUseCase,
    required MarkCompletedUseCase markCompletedUseCase,
    required CallDirectoryService callDirectoryService,
  })  : _getAllCallsUseCase = getAllCallsUseCase,
        _saveCallUseCase = saveCallUseCase,
        _updateCallNotesUseCase = updateCallNotesUseCase,
        _deleteCallUseCase = deleteCallUseCase,
        _markCompletedUseCase = markCompletedUseCase,
        _callDirectoryService = callDirectoryService,
        super(CallHistoryState());

  Future<void> loadCalls() async {
    print('[DEBUG] CallHistoryNotifier: Starting loadCalls...');
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAllCallsUseCase(NoParams());
    result.fold(
      (failure) {
        print('[DEBUG] CallHistoryNotifier: Load failed with failure: $failure');
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (calls) {
        final sortedCalls = List<CallHistoryEntity>.from(calls)
          ..sort((a, b) => b.callTime.compareTo(a.callTime));
        final pending = sortedCalls.where((c) => c.status == AppConstants.statusPending).toList();
        print('[DEBUG] CallHistoryNotifier: Load successful. Total: ${calls.length}, Pending: ${pending.length}');
        state = state.copyWith(
          isLoading: false,
          calls: sortedCalls,
          pendingCalls: pending,
        );
      },
    );
  }

  Future<void> saveCall(CallHistoryEntity call) async {
    print('[DEBUG] CallHistoryNotifier: Saving call for ${call.contactName} (${call.phoneNumber})...');
    final result = await _saveCallUseCase(call);
    
    result.fold(
      (failure) {
        print('[DEBUG] CallHistoryNotifier: Save failed: $failure');
        state = state.copyWith(error: failure.message);
      },
      (_) {
        // Handle success with proper async
        _handleSaveSuccess(call);
      },
    );
  }

  Future<void> _handleSaveSuccess(CallHistoryEntity call) async {
    print('[DEBUG] CallHistoryNotifier: Save successful. Refreshing calls...');
    await loadCalls();
    
    // Sync with iOS CallKit
    if (Platform.isIOS) {
      await _callDirectoryService.syncData(state.calls);
    }
    
    // Sync with Android Call Screening
    if (Platform.isAndroid) {
      print('[DEBUG] CallHistoryNotifier: Syncing to Android SharedPreferences...');
      await SharedPreferencesService.saveNoteToSharedPrefs(
        call.phoneNumber,
        call.notes ?? '',
      );
      print('[DEBUG] CallHistoryNotifier: Android sync complete');
      await _syncToAndroidCallScreening();
    }
  }

  Future<void> updateNotes(String id, String notes) async {
    print('[DEBUG] CallHistoryNotifier: Updating notes for call $id...');
    
    // Find phone number before updating
    final phoneNumber = state.calls.firstWhere((c) => c.id == id).phoneNumber;
    
    final result = await _updateCallNotesUseCase(UpdateNotesParams(id: id, notes: notes));
    
    result.fold(
      (failure) {
        print('[DEBUG] CallHistoryNotifier: Update notes failed: $failure');
        state = state.copyWith(error: failure.message);
      },
      (_) {
        _handleUpdateSuccess(phoneNumber, notes);
      },
    );
  }

  Future<void> _handleUpdateSuccess(String phoneNumber, String notes) async {
    print('[DEBUG] CallHistoryNotifier: Update notes successful. Refreshing calls...');
    await loadCalls();
    
    // Sync with iOS CallKit
    if (Platform.isIOS) {
      await _callDirectoryService.syncData(state.calls);
    }
    
    // Sync with Android Call Screening
    if (Platform.isAndroid) {
      print('[DEBUG] CallHistoryNotifier: Syncing updated notes to Android SharedPreferences...');
      await SharedPreferencesService.saveNoteToSharedPrefs(phoneNumber, notes);
      print('[DEBUG] CallHistoryNotifier: Android sync complete');
      await _syncToAndroidCallScreening();
    }
  }

  Future<void> deleteCall(String id) async {
    print('[DEBUG] CallHistoryNotifier: Deleting call $id...');
    
    // Find phone number before deleting
    final phoneNumber = state.calls.any((c) => c.id == id) 
        ? state.calls.firstWhere((c) => c.id == id).phoneNumber 
        : null;
        
    final result = await _deleteCallUseCase(id);
    
    result.fold(
      (failure) {
        print('[DEBUG] CallHistoryNotifier: Delete failed: $failure');
        state = state.copyWith(error: failure.message);
      },
      (_) {
        _handleDeleteSuccess(phoneNumber);
      },
    );
  }

  Future<void> _handleDeleteSuccess(String? phoneNumber) async {
    print('[DEBUG] CallHistoryNotifier: Delete successful. Refreshing calls...');
    await loadCalls();
    
    if (Platform.isAndroid && phoneNumber != null) {
      print('[DEBUG] CallHistoryNotifier: Removing note from Android SharedPreferences...');
      await SharedPreferencesService.deleteNoteFromSharedPrefs(phoneNumber);
      print('[DEBUG] CallHistoryNotifier: Android removal complete');
      await _syncToAndroidCallScreening();
    }
  }

  Future<void> markCompleted(String id) async {
    print('[DEBUG] CallHistoryNotifier: Marking call $id as COMPLETED...');
    final result = await _markCompletedUseCase(id);
    
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => loadCalls(),
    );
  }


  Future<void> _syncToAndroidCallScreening() async {
    await CallScreeningService.syncCallDirectory();
  }
}