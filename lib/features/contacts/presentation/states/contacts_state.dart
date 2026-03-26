import '../../domain/entities/contact_entity.dart';

class ContactsState {
  final List<ContactEntity> contacts;
  final List<ContactEntity> filtered;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  ContactsState({
    this.contacts = const [],
    this.filtered = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  ContactsState copyWith({
    List<ContactEntity>? contacts,
    List<ContactEntity>? filtered,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      filtered: filtered ?? this.filtered,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
