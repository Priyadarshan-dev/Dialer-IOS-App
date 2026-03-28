import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dialer_app_poc/features/contacts/presentation/screens/contacts_screen.dart';
import 'package:dialer_app_poc/features/call_history/presentation/screens/call_history_screen.dart';
import 'package:dialer_app_poc/features/call_history/presentation/screens/widgets/notes_popup_dialog.dart';
import 'package:dialer_app_poc/features/contacts/presentation/screens/dialpad_screen.dart';
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

  await Future.delayed(const Duration(milliseconds: 500));

  // NATIVE CONTACTS DISABLED (CRM Mode)
  // To re-enable, uncomment the lines below:
  // print('[DEBUG] App: Requesting Contacts permission...');
  // final status = await Permission.contacts.request();
  // print('[DEBUG] App: Contacts permission status: $status');

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
    
    // Safety check: Only trigger popups for calls initiated within the last 2 hours
    final validPendingCalls = callHistoryState.pendingCalls.where((c) {
      return DateTime.now().difference(c.callTime).inHours < 2;
    }).toList();
    
    if (validPendingCalls.isNotEmpty) {
      print('[DEBUG] AppLifecycle: Found ${validPendingCalls.length} valid pending calls. Triggering single popup for the latest.');
      _showSingleNotesPopup(validPendingCalls.first);
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
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF007AFF), // iOS Blue
        surface: Colors.black,
        secondary: Color(0xFF1C1C1E), // iOS Dark Gray
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFF007AFF)),
        actionsIconTheme: const IconThemeData(color: Color(0xFF007AFF)),
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF161616),
        selectedItemColor: Color(0xFF007AFF),
        unselectedItemColor: Color(0xFF8E8E93),
        selectedLabelStyle: TextStyle(fontSize: 10),
        unselectedLabelStyle: TextStyle(fontSize: 10),
        type: BottomNavigationBarType.fixed,
      ),
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: themeData,
      themeMode: ThemeMode.dark,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends ConsumerWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);

    final List<Widget> screens = [
      const CallHistoryScreen(), // Recents
      const ContactsScreen(),   // Contacts
      DialpadScreen(),           // Keypad
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(navigationProvider.notifier).state = index,
        backgroundColor: const Color(0xFF1C1C1E),
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: const Color(0xFF8E8E93),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_filled),
            label: 'Recents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dialpad),
            label: 'Keypad',
          ),
        ],
      ),
    );
  }
}
