import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/data/datasources/call_history_local_datasource.dart';
import 'package:dialer_app_poc/features/call_history/data/models/call_history_model.dart';
import 'package:dialer_app_poc/features/call_history/data/repositories/call_history_repository_impl.dart';
import 'package:dialer_app_poc/features/call_history/domain/repositories/call_history_repository.dart';
import 'package:dialer_app_poc/features/call_history/domain/usecases/call_history_usecases.dart';
import 'package:dialer_app_poc/features/call_history/presentation/providers/call_history_provider.dart';
import 'package:dialer_app_poc/features/call_history/presentation/states/call_history_state.dart';
import 'package:dialer_app_poc/features/contacts/data/datasources/contact_local_datasource.dart';
import 'package:dialer_app_poc/features/contacts/data/repositories/contact_repository_impl.dart';
import 'package:dialer_app_poc/features/contacts/domain/repositories/contact_repository.dart';
import 'package:dialer_app_poc/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:dialer_app_poc/features/contacts/presentation/providers/contacts_provider.dart';
import 'package:dialer_app_poc/features/contacts/presentation/states/contacts_state.dart';
import 'package:dialer_app_poc/core/services/call_directory_service.dart';

// --- Contacts Providers ---

final contactLocalDataSourceProvider = Provider<ContactLocalDataSource>((ref) {
  return ContactLocalDataSourceImpl();
});

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  final localDataSource = ref.watch(contactLocalDataSourceProvider);
  return ContactRepositoryImpl(localDataSource);
});

final getContactsUseCaseProvider = Provider<GetContactsUseCase>((ref) {
  final repository = ref.watch(contactRepositoryProvider);
  return GetContactsUseCase(repository);
});

final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  final useCase = ref.watch(getContactsUseCaseProvider);
  return ContactsNotifier(useCase);
});

// --- Call History Providers ---

final callHistoryBoxProvider = Provider<Box<CallHistoryModel>>((ref) {
  return Hive.box<CallHistoryModel>(AppConstants.callHistoryBox);
});

final callHistoryLocalDataSourceProvider = Provider<CallHistoryLocalDataSource>((ref) {
  final box = ref.watch(callHistoryBoxProvider);
  return CallHistoryLocalDataSourceImpl(box);
});

final callHistoryRepositoryProvider = Provider<CallHistoryRepository>((ref) {
  final localDataSource = ref.watch(callHistoryLocalDataSourceProvider);
  return CallHistoryRepositoryImpl(localDataSource);
});

final getAllCallsUseCaseProvider = Provider<GetAllCallsUseCase>((ref) {
  final repository = ref.watch(callHistoryRepositoryProvider);
  return GetAllCallsUseCase(repository);
});

final saveCallUseCaseProvider = Provider<SaveCallUseCase>((ref) {
  final repository = ref.watch(callHistoryRepositoryProvider);
  return SaveCallUseCase(repository);
});

final updateCallNotesUseCaseProvider = Provider<UpdateCallNotesUseCase>((ref) {
  final repository = ref.watch(callHistoryRepositoryProvider);
  return UpdateCallNotesUseCase(repository);
});

final deleteCallUseCaseProvider = Provider<DeleteCallUseCase>((ref) {
  final repository = ref.watch(callHistoryRepositoryProvider);
  return DeleteCallUseCase(repository);
});

final markCompletedUseCaseProvider = Provider<MarkCompletedUseCase>((ref) {
  final repository = ref.watch(callHistoryRepositoryProvider);
  return MarkCompletedUseCase(repository);
});

final callDirectoryServiceProvider = Provider<CallDirectoryService>((ref) {
  return CallDirectoryService();
});

final callHistoryProvider = StateNotifierProvider<CallHistoryNotifier, CallHistoryState>((ref) {
  return CallHistoryNotifier(
    getAllCallsUseCase: ref.watch(getAllCallsUseCaseProvider),
    saveCallUseCase: ref.watch(saveCallUseCaseProvider),
    updateCallNotesUseCase: ref.watch(updateCallNotesUseCaseProvider),
    deleteCallUseCase: ref.watch(deleteCallUseCaseProvider),
    markCompletedUseCase: ref.watch(markCompletedUseCaseProvider),
    callDirectoryService: ref.watch(callDirectoryServiceProvider),
  );
});
