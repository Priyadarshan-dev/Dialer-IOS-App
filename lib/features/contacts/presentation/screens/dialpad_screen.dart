import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dialer_app_poc/providers.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/core/services/notification_service.dart';
import 'package:dialer_app_poc/features/contacts/presentation/screens/add_app_contact_screen.dart';

class DialpadScreen extends ConsumerStatefulWidget {
  const DialpadScreen({super.key});

  @override
  ConsumerState<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends ConsumerState<DialpadScreen> {
  String _phoneNumber = '';

  void _onNumberPressed(String value) {
    if (_phoneNumber.length < 15) {
      setState(() {
        _phoneNumber += value;
      });
    }
  }

  void _onBackspace() {
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      });
    }
  }

  Future<void> _onCall() async {
    if (_phoneNumber.isEmpty) return;

    // Resolve name from contacts if available
    final contactsState = ref.read(contactsProvider);
    String resolvedName = '';
    final rawInput = _phoneNumber.replaceAll(RegExp(r'\D'), '');

    for (var contact in contactsState.contacts) {
      final matches = contact.phoneNumbers.any((p) => 
          p.replaceAll(RegExp(r'\D'), '') == rawInput
      );
      if (matches) {
        resolvedName = contact.displayName;
        break;
      }
    }

    final callHistory = CallHistoryEntity(
      id: const Uuid().v4(),
      contactName: resolvedName,
      phoneNumber: _phoneNumber,
      callTime: DateTime.now(),
      status: AppConstants.statusPending,
    );

    // 1. Save pending call entry
    await ref.read(callHistoryProvider.notifier).saveCall(callHistory);

    // 2. Initiate call locally
    print('[DEBUG] DialpadScreen: Initiating call to $_phoneNumber');
    
    // Switch tab to Recents BEFORE the call starts or immediately after
    // This ensures that when the user returns to the app, they see Recents.
    ref.read(navigationProvider.notifier).state = 0;

    final res = await FlutterPhoneDirectCaller.callNumber(_phoneNumber);

    setState(() {
      _phoneNumber = '';
    });
    
    // 3. iOS Workaround: Show notification reminder
    if (res == true || Platform.isIOS) {
      await NotificationService().showCallReminder(_phoneNumber);
    }

    if (res == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not initiate call')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Display Number
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _phoneNumber,
                style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (_phoneNumber.isNotEmpty)
              CupertinoButton(
                child: const Text('Add Number', style: TextStyle(color: Color(0xFF007AFF), fontSize: 17)),
                onPressed: () {
                  Navigator.push<bool>(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => AddAppContactScreen(initialPhoneNumber: _phoneNumber),
                      fullscreenDialog: true,
                    ),
                  ).then((success) {
                    if (success == true) {
                      setState(() {
                        _phoneNumber = '';
                      });
                    }
                    ref.read(contactsProvider.notifier).loadContacts();
                  });
                },
              ),
            const Spacer(),
            // Dialpad Grid
            _buildDialpad(),
            const SizedBox(height: 20),
            // Bottom Actions
            _buildActions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDialpad() {
    final keys = [
      ['1', ''], ['2', 'ABC'], ['3', 'DEF'],
      ['4', 'GHI'], ['5', 'JKL'], ['6', 'MNO'],
      ['7', 'PQRS'], ['8', 'TUV'], ['9', 'WXYZ'],
      ['*', ''], ['0', '+'], ['#', ''],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 26,
          childAspectRatio: 1.0,
        ),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index][0];
          final sub = keys[index][1];
          return _DialButton(
            number: key,
            letters: sub,
            onPressed: () => _onNumberPressed(key),
          );
        },
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), // Empty space to balance the backspace icon
          GestureDetector(
            onTap: _onCall,
            child: Container(
              width: 75,
              height: 75,
              decoration: const BoxDecoration(
                color: Color(0xFF34C759),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.white, size: 35),
            ),
          ),
          SizedBox(
            width: 40,
            child: _phoneNumber.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.backspace, color: Color(0xFF8E8E93), size: 28),
                  onPressed: _onBackspace,
                )
              : null,
          ),
        ],
      ),
    );
  }
}

class _DialButton extends StatelessWidget {
  final String number;
  final String letters;
  final VoidCallback onPressed;

  const _DialButton({
    required this.number,
    required this.letters,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF333333), // Lighter gray for dialpad buttons
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
