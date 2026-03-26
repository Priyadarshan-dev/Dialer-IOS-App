# Swift Call (dialer_app_poc)

Swift Call is a robust Flutter-based dialer application providing advanced contact management and caller identification features across Android and iOS platforms.

## Overview

This project is built using:
- **State Management**: [Riverpod (`flutter_riverpod`)](https://pub.dev/packages/flutter_riverpod)
- **Local Storage**: [Hive (`hive`, `hive_flutter`)](https://pub.dev/packages/hive) & Shared Preferences
- **Key Flutter Plugins**:
  - `flutter_contacts`: For fetching and managing device contacts.
  - `flutter_phone_direct_caller`: For initiating direct phone calls.
  - `permission_handler`: For managing telecom, contacts, and overlay permissions.
  - `flutter_local_notifications`: For handling local notifications.

## Project Structure
The app follows a feature-first componentized architecture:
- `/lib/core/`: Contains core utilities, routing, network layers, and shared UI components.
- `/lib/features/`: Contains feature modules (e.g., `contacts`, `dialer`, `call_history`).
  - Each feature generally contains `presentation` (screens, widgets), `domain` (models), and `data` (repositories).
- `/lib/providers.dart`: Centralized Riverpod provider definitions.
- `/lib/main.dart` & `/lib/app.dart`: App entry points and global theming.

---

## Native Platform Setup

Implementing a custom dialer requires deep integration with native telecom layers. Below are the platform-specific configurations for Swift Call.

### Android Configuration

#### 1. Permissions (`AndroidManifest.xml`)
The Android application requires a comprehensive set of permissions to function as a dialer and handle calls:
- `READ_CONTACTS`: For syncing app contacts.
- `CALL_PHONE` & `ANSWER_PHONE_CALLS`: For making and answering phone calls.
- `READ_CALL_LOG`: For reading history.
- `READ_PHONE_STATE`: For detecting incoming calls.
- `BIND_SCREENING_SERVICE`: Necessary for custom call screening.
- `SYSTEM_ALERT_WINDOW`: Required for drawing the custom call overlay (`CallNotesOverlay`) over other apps during an incoming call.

#### 2. Services
The app implements several background services to handle telephony features securely:
- **`LiquidDialerCallScreeningService`**: Implements the `android.telecom.CallScreeningService` action. This allows the app to intercept incoming calls, process the caller ID, and optionally block calls if needed.
- **`CallNotesOverlay`**: A custom service used to display an overlay (like caller notes) on top of the default or ongoing incoming call screen using `SYSTEM_ALERT_WINDOW`.

### iOS Configuration

#### 1. Call Directory Extension for Caller ID
To provide caller identification and custom labels (e.g., notes synced from the app) on iOS, the app uses a **Call Directory Extension** (`CXCallDirectoryManager`).
- This follows roughly a Truecaller-style architecture, where known numbers and their associated notes/labels are pre-synced to the iOS system.
- When an incoming call arrives, iOS natively looks up the number in this pre-synced database and displays the assigned label without waking up the main app.

#### 2. App Group Data Sharing
Because the main Flutter app and the Call Directory Extension are separate processes in iOS, they share data via **App Groups**.
- The main app writes the numbers and caller labels (contact notes) to a shared file within the App Group container.
- **Data Formatting Rule**: CallKit requires phone numbers to be sorted strictly numerically (not alphabetically) before they can be processed by the extension. Our implementation uses a custom `JSONSerialization` wrapper to handle this requirement when writing to the shared container.
 
#### 3. AppDelegate Setup (`AppDelegate.swift`)
The iOS `AppDelegate` has specialized logic to handle background synchronization:
- Uses `FlutterImplicitEngineBridge` for background engine registration.
- Sets up a dedicated `MethodChannel` (`com.liquid.dialer/call_directory`) to handle `syncAndReload` commands from Flutter.
- Receives the synced notes, saves them to the shared App Group file in the required CallKit numerical-sorted format, and triggers `CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier:)` to force iOS to recognize the newly synced numbers.

---

## Getting Started

1. **Install Dependencies**: `flutter pub get`
2. **Setup Native Extensions**:
   - iOS components rely heavily on `pod install` within the `/ios/` directory to fetch necessary dependencies for the extensions. Ensure Xcode is updated (minimum required iOS target is 12+).
   - For Android, ensure you have the correct `compileSdkVersion` setup as per the native requirements in the `build.gradle.kts`.
3. **Run App**: Build natively or run using `flutter run`.