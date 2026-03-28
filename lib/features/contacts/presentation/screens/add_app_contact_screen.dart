import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/contacts/data/models/app_contact_model.dart';
import 'package:dialer_app_poc/core/services/call_directory_service.dart';
import 'package:dialer_app_poc/providers.dart';

class AddAppContactScreen extends ConsumerStatefulWidget {
  final dynamic existingContact;
  final String? initialPhoneNumber;
  
  const AddAppContactScreen({Key? key, this.existingContact, this.initialPhoneNumber}) : super(key: key);

  @override
  ConsumerState<AddAppContactScreen> createState() => _AddAppContactScreenState();
}

class _AddAppContactScreenState extends ConsumerState<AddAppContactScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    String firstName = '';
    String lastName = '';
    String existingNotes = '';
    
    if (widget.existingContact != null) {
      final names = widget.existingContact!.displayName.split(' ');
      firstName = names.first;
      if (names.length > 1) {
        lastName = names.sublist(1).join(' ');
      }
      
      try {
        final box = Hive.box<AppContactModel>(AppConstants.appContactsBox);
        final appContact = box.get(widget.existingContact!.id);
        if (appContact != null) {
          existingNotes = appContact.notes ?? '';
        }
      } catch (_) {}
    }

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _phoneController = TextEditingController(
      text: widget.existingContact?.phoneNumbers.isNotEmpty == true 
          ? widget.existingContact!.phoneNumbers.first 
          : widget.initialPhoneNumber ?? ''
    );
    _notesController = TextEditingController(text: existingNotes);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    final name = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
    if (name.isEmpty || _phoneController.text.trim().isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final newContact = AppContactModel(
        id: widget.existingContact?.id,
        name: name,
        phoneNumber: _phoneController.text.trim(),
        notes: _notesController.text.trim(),
      );

      final box = Hive.box<AppContactModel>(AppConstants.appContactsBox);
      await box.put(newContact.id, newContact);
      await CallDirectoryService().syncAllData();

      if (mounted) {
        Navigator.pop(context, true); // Return true when successfully saved
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        leadingWidth: 100,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF007AFF), fontSize: 17)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingContact != null ? 'Edit Contact' : 'New Contact',
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          _isSaving 
            ? const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: CupertinoActivityIndicator()))
            : CupertinoButton(
                padding: const EdgeInsets.only(right: 16),
                child: const Text('Done', style: TextStyle(color: Color(0xFF007AFF), fontSize: 17, fontWeight: FontWeight.bold)),
                onPressed: _saveContact,
              ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Placeholder
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF8E8E93),
              child: Icon(Icons.person, color: Colors.white, size: 60),
            ),
            CupertinoButton(
              child: const Text('Add Photo', style: TextStyle(color: Color(0xFF007AFF), fontSize: 15)),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            
            // Name Fields
            _buildInputGroup([
              _buildTextField(_firstNameController, 'First Name'),
              const Divider(color: Color(0xFF38383A), height: 1, indent: 16),
              _buildTextField(_lastNameController, 'Last Name'),
            ]),
            
            const SizedBox(height: 20),
            
            // Phone Field
            _buildInputGroup([
              _buildTextField(_phoneController, 'Phone', keyboardType: TextInputType.phone),
            ]),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String placeholder, {TextInputType? keyboardType, int? maxLines = 1}) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      placeholderStyle: const TextStyle(color: Color(0xFF8E8E93)),
      style: const TextStyle(color: Colors.white),
      decoration: const BoxDecoration(color: Colors.transparent),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}
