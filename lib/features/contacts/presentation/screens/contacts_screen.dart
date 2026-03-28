import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dialer_app_poc/providers.dart';
import 'package:dialer_app_poc/features/contacts/presentation/screens/add_app_contact_screen.dart';
import 'package:dialer_app_poc/features/contacts/presentation/screens/contact_details_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final Map<String, GlobalKey> _keys = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsProvider);
    final notifier = ref.read(contactsProvider.notifier);

    // Group contacts by initial
    final groupedContacts = _groupContacts(state.filtered);
    final sortedKeys = groupedContacts.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF007AFF), size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddAppContactScreen(),
                  fullscreenDialog: true,
                ),
              ).then((_) => ref.read(contactsProvider.notifier).loadContacts());
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Contacts Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: const Text(
                    'Contacts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93)),
                      suffixIcon: _isSearching ? IconButton(
                        icon: const Icon(Icons.cancel, color: Color(0xFF8E8E93)),
                        onPressed: () {
                          _searchController.clear();
                          notifier.searchContacts('');
                          setState(() => _isSearching = false);
                        },
                      ) : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() => _isSearching = value.isNotEmpty);
                      notifier.searchContacts(value);
                    },
                  ),
                ),
              ),

              // Contact List Grouped by Letter
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final key = sortedKeys[index];
                    final contacts = groupedContacts[key]!;
                    _keys[key] = GlobalKey();
                    return Column(
                      key: _keys[key],
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Letter Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(color: Color(0xFF38383A), height: 1, indent: 16),
                        // Contacts in group
                        ...contacts.map((contact) => _buildContactTile(context, contact)),
                      ],
                    );
                  },
                  childCount: sortedKeys.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          
          // Alphabet Index Scrollbar removed as requested

        ],
      ),
    );
  }

  Map<String, List<dynamic>> _groupContacts(List<dynamic> contacts) {
    final groups = <String, List<dynamic>>{};
    for (var contact in contacts) {
      final initial = contact.displayName.isNotEmpty 
          ? contact.displayName[0].toUpperCase()
          : '#';
      if (!groups.containsKey(initial)) {
        groups[initial] = [];
      }
      groups[initial]!.add(contact);
    }
    return groups;
  }

  Widget _buildContactTile(BuildContext context, dynamic contact) {
    return Column(
      children: [
        ListTile(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => ContactDetailsScreen(contact: contact)),
            );
          },
          title: Text(
            contact.displayName,
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          minVerticalPadding: 0,
          visualDensity: VisualDensity.compact,
        ),
        const Divider(color: Color(0xFF38383A), height: 1, indent: 16),
      ],
    );
  }

}

