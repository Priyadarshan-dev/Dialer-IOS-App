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

    final callHistory = CallHistoryEntity(
      id: const Uuid().v4(),
      contactName: 'Manual Dial',
      phoneNumber: _phoneNumber,
      callTime: DateTime.now(),
      status: AppConstants.statusPending,
    );

    // 1. Save pending call entry
    await ref.read(callHistoryProvider.notifier).saveCall(callHistory);

    // 2. Initiate call locally
    print('[DEBUG] DialpadScreen: Initiating call to $_phoneNumber');
    final res = await FlutterPhoneDirectCaller.callNumber(_phoneNumber);
    
    // 3. iOS Workaround: Show notification reminder
    if (res == true || Platform.isIOS) {
      await NotificationService().showCallReminder('Manual Dial ($_phoneNumber)');
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),
              // Display Number
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _phoneNumber.isEmpty ? 'Enter Number' : _phoneNumber,
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: _phoneNumber.isEmpty ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Dialpad Grid
              _buildDialpad(),
              const SizedBox(height: 24),
              // Bottom Actions
              _buildActions(),
              const SizedBox(height: 32),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 24,
          childAspectRatio: 1,
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
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(width: 64), // Spacer for centering
          // Call Button
          GestureDetector(
            onTap: _onCall,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.call_rounded, color: Colors.white, size: 36),
            ),
          ),
          // Backspace Button
          SizedBox(
            width: 64,
            child: IconButton(
              onPressed: _onBackspace,
              icon: const Icon(Icons.backspace_rounded, color: Color(0xFF94A3B8), size: 28),
            ),
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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
