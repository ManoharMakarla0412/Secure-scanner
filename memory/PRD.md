# QR Barcode Scanner & Generator - After Call Overlay

## Original Problem Statement
Fix the after-call overlay functionality to have complete end-to-end functionality after the overlay is working properly. The overlay should appear after calls end and provide action buttons for users.

## Architecture
- **Platform**: Flutter/Dart mobile application (Android)
- **UI Framework**: Material Design with clean light theme
- **Backend Services**: 
  - Firebase (Analytics, Crashlytics)
  - Google Mobile Ads
- **Phone Integration**: 
  - `phone_state` package for call lifecycle detection
  - `flutter_overlay_window` for system overlay functionality
  - Native Android BroadcastReceiver for call events

## User Personas
1. **Primary Users**: Mobile phone users who want to quickly share contact information via QR codes after phone calls
2. **Secondary Users**: Users who want to scan/generate QR codes for various purposes

## Core Requirements (Static)
1. Display overlay when phone call ends
2. Show contact information (phone number) in overlay
3. Provide "Open App" button to launch main app
4. Provide "Share QR" button to share contact QR code
5. Provide "Create Other QR" option to navigate to QR generator
6. AdMob integration for monetization

## What's Been Implemented

### January 2026
- **Complete Call Overlay Functionality**:
  - Added "Open App" button (green) - Opens the main SecureScan app
  - Added "Share QR" button (blue) - Generates and shares contact QR code image
  - Added "Create Other QR (Text, URL)" link - Navigates to QR generator screen
  - Improved QR code sharing - Now generates actual QR image file and shares via system share sheet
  - Added platform channel method `openApp` with route parameter support
  - Added `/create-qr` route handling in app.dart
  - Updated MainActivity.kt with proper intent flags for launching from overlay
  - Set default overlay state so UI shows immediately on overlay display

- **Bug Fixes - Overlay Triggering Issues**:
  - Fixed overlay showing on app launch by adding call state tracking (`wasInCall`, `lastStatus`)
  - Enhanced CallManager with proper call lifecycle tracking (INCOMING → STARTED → ENDED)
  - Updated CallReceiver.kt with state machine logic to only trigger overlay after actual calls
  - Added overlay cleanup on app start to close any lingering overlays
  - Prevented `/overlay` route from being used as initial route in MainActivity
  - Added protection against overlay route in onNewIntent handler
  - Enhanced debugging with detailed logging for call state transitions

- **UI Redesign - Clean Light Theme Overlay**:
  - Completely redesigned overlay to match provided mockup
  - Clean white background with light theme
  - Header with X close button (left) and SecureScan branding with QR icon (right)
  - Large "Call Ended" heading with "with [Contact Name]" subtitle
  - Two blue action buttons side by side:
    - "Create Contact QR" - Opens QR generator for contact
    - "Scan New Code" - Opens main app scanner
  - Dark ad section at bottom with native video ad placeholder
  - Full screen layout matching the mockup exactly

- **Full Screen Overlay Fixes (Jan 2026)**:
  - Changed WindowSize to `fullCover` for height and `matchParent` for width
  - Added proper status bar and bottom navigation padding
  - Fixed SafeArea issue by manually calculating padding
  - Updated alignment to `topCenter` with position `(0, 0)`
  - Fixed Android manifest overlay service `foregroundServiceType` to `specialUse`
  - Added proper `PROPERTY_SPECIAL_USE_FGS_SUBTYPE` for Android 14+ compatibility

- **Call Detection - All Scenarios Covered (Jan 2026)**:
  - ✅ Incoming call → Answer → Hang up (RINGING → OFFHOOK → IDLE)
  - ✅ Incoming call → Reject/Decline (RINGING → IDLE)
  - ✅ Incoming call → Missed/caller hangs up (RINGING → IDLE)
  - ✅ Outgoing call → Connected → Hang up (OUTGOING → OFFHOOK → IDLE)
  - ✅ Outgoing call → No answer/Busy (OUTGOING → IDLE)
  - ✅ Outgoing call → Cancelled by user (OUTGOING → IDLE)
  - Added `wasOutgoingCall` flag to track outgoing calls separately
  - Fixed logic to show overlay for outgoing calls that don't connect

- **Rebranding (Jan 2026)**:
  - Changed app name from "SecureScan" to "QR Barcode Scanner & Generator"
  - Updated overlay header with new branding (two-line text)
  - Using app icon from `assets/QR.png` in overlay header
  - Updated overlay notification title

### Files Modified
- `/app/lib/widgets/call_overlay_widget.dart` - Main overlay UI with action buttons
- `/app/lib/app.dart` - Added route handling for `/create-qr`
- `/app/android/app/src/main/kotlin/com/example/securescan/MainActivity.kt` - Enhanced app launching
- `/app/lib/services/call_manager.dart` - Call state handling and overlay triggering
- `/app/android/app/src/main/kotlin/com/example/securescan/CallReceiver.kt` - Native call detection

### January 2026 - Complete Rewrite
- **Overlay Widget Completely Rewritten**:
  - Uses MaterialApp wrapper for proper theme/context
  - LayoutBuilder for responsive constraints
  - Stack with Positioned.fill for true full screen
  - SingleChildScrollView to handle overflow on small screens
  - Proper safe area handling via MediaQuery padding
  - Material+InkWell for proper touch feedback
  - Separated StatelessWidget components for buttons/placeholder
  - Clean, minimal imports
  
- **CallManager Updates**:
  - positionGravity: PositionGravity.none for static overlay
  - Increased delays for overlay initialization
  - Auto permission request if not granted

- **Android 12+ Background Service Fix (Jan 2026)**:
  - Created `OverlayActivity.kt` - A full-screen FlutterActivity that uses `overlayMain` dart entry point
  - Bypasses `BackgroundServiceStartNotAllowedException` by launching an Activity instead of Service
  - Activity shows over lock screen (`setShowWhenLocked`, `setTurnScreenOn`)
  - Added method channel `com.securescan.securescan/overlay` for passing call data
  - CallReceiver now calls `OverlayActivity.launch()` instead of trying to start overlay service
  - Overlay widget listens to both overlay stream AND method channel for call data
  - Close button properly finishes activity with `SystemNavigator.pop()`

## Prioritized Backlog

### P0 (Critical)
- ✅ Complete overlay action buttons (Open App, Share QR, Create Other QR)

### P1 (High Priority)
- Test overlay on physical device with actual phone calls
- Verify CallReceiver receives call end events properly
- Test QR code sharing functionality

### P2 (Medium Priority)
- Add caller name lookup (if available in contacts)
- Add vCard QR code generation for full contact details
- Improve overlay animation transitions

### P3 (Low Priority)
- Add haptic feedback on button taps
- Add sound effects for overlay actions
- Dark/Light theme for overlay based on system settings

## Next Tasks
1. Build and test on Android device
2. Test call end detection flow
3. Test "Open App" navigation
4. Test "Share QR" image generation and sharing
5. Test "Create Other QR" navigation to generator screen
