import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dialer_app_poc/features/contacts/presentation/screens/contacts_screen.dart';
import 'package:dialer_app_poc/features/call_history/presentation/screens/call_history_screen.dart';
import 'package:dialer_app_poc/features/call_history/presentation/screens/widgets/notes_popup_dialog.dart';
import 'package:dialer_app_poc/providers.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class CRMApp extends ConsumerStatefulWidget {
  const CRMApp({super.key});

  @override
  ConsumerState<CRMApp> createState() => _CRMAppState();
}

class _CRMAppState extends ConsumerState<CRMApp> with WidgetsBindingObserver {
  bool _wasPaused = false;
  bool _isShowingPopup = false;
  DateTime? _lastResumeTime;

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addObserver(this);
  //   _initApp();
  // }

  // Future<void> _initApp() async {
  //   print('[DEBUG] App: Initializing app and requesting permissions...');
  //   await Permission.contacts.request();
    
  //   if (mounted) {
  //     ref.read(contactsProvider.notifier).loadContacts();
  //     ref.read(callHistoryProvider.notifier).loadCalls();
  //   }
  // }

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initApp(); // ✅ run AFTER UI is ready
  });
}

Future<void> _initApp() async {
  print('[DEBUG] App: Initializing app...');

  // Wait for the native rootViewController to be fully ready on iOS
  await Future.delayed(const Duration(milliseconds: 500));

  // Explicitly request contacts permission before loading contacts
  print('[DEBUG] App: Requesting Contacts permission...');
  final status = await Permission.contacts.request();
  print('[DEBUG] App: Contacts permission status: $status');

  if (mounted) {
    ref.read(contactsProvider.notifier).loadContacts();
    ref.read(callHistoryProvider.notifier).loadCalls();
  }
}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[DEBUG] AppLifecycle: State changed to $state');
    
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
      print('[DEBUG] AppLifecycle: App backgrounded (paused)');
    }

    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastResumeTime != null && now.difference(_lastResumeTime!).inSeconds < 2) {
        print('[DEBUG] AppLifecycle: Ignoring rapid resume event (debounced)');
        return;
      }
      _lastResumeTime = now;

      print('[DEBUG] AppLifecycle: App resumed. WasPaused: $_wasPaused');
      if (_wasPaused) {
        _wasPaused = false;
        print('[DEBUG] AppLifecycle: Resumed from background, refreshing calls...');
        Future.delayed(const Duration(milliseconds: 500), () {
          ref.read(callHistoryProvider.notifier).loadCalls().then((_) {
            _checkPendingCalls();
          });
        });
      }
    }
  }

  void _checkPendingCalls() {
    if (_isShowingPopup) {
      print('[DEBUG] AppLifecycle: Already showing a popup, skipping check');
      return;
    }

    print('[DEBUG] AppLifecycle: Checking for pending calls...');
    final callHistoryState = ref.read(callHistoryProvider);
    
    if (callHistoryState.pendingCalls.isNotEmpty) {
      print('[DEBUG] AppLifecycle: Found ${callHistoryState.pendingCalls.length} pending calls. Triggering single popup for the latest.');
      _showSingleNotesPopup(callHistoryState.pendingCalls.first);
    } else {
      print('[DEBUG] AppLifecycle: No pending calls found.');
    }
  }

  void _showSingleNotesPopup(CallHistoryEntity call) {
    final navContext = navigatorKey.currentContext;
    if (navContext == null) {
      print('[DEBUG] AppLifecycle: Navigator context is NULL, cannot show dialog');
      return;
    }

    _isShowingPopup = true;
    print('[DEBUG] AppLifecycle: Showing NotesPopupDialog for call ${call.id}');
    showDialog(
      context: navContext,
      barrierDismissible: false,
      builder: (context) => NotesPopupDialog(
        call: call,
        isEdit: false,
      ),
    ).then((_) {
      _isShowingPopup = false;
      print('[DEBUG] AppLifecycle: Dialog closed for call ${call.id}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1), // Modern Indigo
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: const Color(0xFFF8FAFC),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        titleTextStyle: GoogleFonts.outfit(
          color: const Color(0xFF1E293B),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ContactsScreen(),
    const CallHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 72,
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: const Color(0xFF6366F1),
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 12),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.contacts_rounded, size: 26),
                  activeIcon: Icon(Icons.contacts_rounded, size: 26),
                  label: 'Contacts',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded, size: 26),
                  activeIcon: Icon(Icons.history_rounded, size: 26),
                  label: 'History',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
