import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/contacts/data/models/app_contact_model.dart';
import 'package:dialer_app_poc/core/services/call_directory_service.dart';
import 'package:dialer_app_poc/core/usecases/usecase.dart';
import 'package:dialer_app_poc/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:dialer_app_poc/features/contacts/presentation/states/contacts_state.dart';

class ContactsNotifier extends StateNotifier<ContactsState> {
  final GetContactsUseCase _getContactsUseCase;

  ContactsNotifier(this._getContactsUseCase) : super(ContactsState());

  Future<void> loadContacts() async {
    print('[DEBUG] ContactsNotifier: Starting loadContacts...');
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getContactsUseCase(NoParams());
    
    result.fold(
      (failure) {
        print('[DEBUG] ContactsNotifier: Load failed with failure: $failure');
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (contacts) {
        print('[DEBUG] ContactsNotifier: Load successful. Found ${contacts.length} contacts.');
        state = state.copyWith(
          isLoading: false,
          contacts: contacts,
          filtered: contacts,
        );
      },
    );
  }

  void searchContacts(String query) {
    print('[DEBUG] ContactsNotifier: Searching for query: "$query"');
    if (query.isEmpty) {
      state = state.copyWith(filtered: state.contacts, searchQuery: query);
    } else {
      final filtered = state.contacts.where((c) {
        return c.displayName.toLowerCase().contains(query.toLowerCase()) ||
               c.phoneNumbers.any((p) => p.contains(query));
      }).toList();
      print('[DEBUG] ContactsNotifier: Filtered to ${filtered.length} matches');
      state = state.copyWith(filtered: filtered, searchQuery: query);
    }
  }

  Future<void> deleteAppContact(String id) async {
    print('[DEBUG] ContactsNotifier: Deleting contact $id...');
    try {
      final box = Hive.box<AppContactModel>(AppConstants.appContactsBox);
      await box.delete(id);
      await CallDirectoryService().syncAllData();
      await loadContacts();
    } catch (e) {
      print('[DEBUG] ContactsNotifier: Failed to delete contact: $e');
    }
  }
}
