import 'dart:async';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart'; // For GlobalKey, NavigatorState if needed explicit
import 'package:securescan/app.dart'; // Import for navigatorKey

class CallManager {
  static final CallManager _instance = CallManager._();

  factory CallManager() => _instance;

  CallManager._();

  // ignore: unused_field
  StreamSubscription<PhoneState>? _subscription;
  // ignore: unused_field
  PhoneStateStatus _lastStatus = PhoneStateStatus.NOTHING;

  Future<void> init() async {
    try {
      await _requestPermissions();
      
      // Register the native CallReceiver dynamically (required for Android 9+)
      try {
        await platform.invokeMethod('registerCallReceiver');
        print("✅ CallReceiver registered successfully");
      } catch (e) {
        print("⚠️ Failed to register CallReceiver: $e");
      }
      
      // Set up method channel handler to receive overlay trigger from native
      platform.setMethodCallHandler((call) async {
        if (call.method == 'triggerOverlay') {
          final status = call.arguments['status'] as String? ?? 'ended';
          final number = call.arguments['number'] as String? ?? 'Unknown';
          print("📞 Overlay trigger received: status=$status, number=$number");
          await _showOverlay("Call $status", number: number);
        }
      });
      print("✅ Method channel handler registered");
      
      _subscription = PhoneState.stream.listen((event) {
        _handlePhoneState(event.status, event.number);
      });
    } catch (e) {
      print("Error initializing CallManager: $e");
    }
  }

  Future<void> _requestPermissions() async {
    // Request multiple permissions required for CallReceiver
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.contacts, // Sometimes needed for number resolution
      Permission.notification, // Required for foreground services on Android 13+
      // Permission.callLog, // If available in package, but 'phone' often covers it
    ].request();
    
    print("Permission Statuses: $statuses");
    
    // Check and request System Alert Window (Overlay) permission
    // Android requires special handling for this permission
    final overlayStatus = await Permission.systemAlertWindow.status;
    if (!overlayStatus.isGranted) {
      final status = await Permission.systemAlertWindow.request();
      if (!status.isGranted) {
        // Optional: Open settings if critical. 
        // For a smoother UX, maybe we should only do this when the user enables the feature explicitly? 
        // But since this is a "Critical Feature" request, we'll try to ensure we have it.
        // openAppSettings() might not go to the overlay page directly.
      }
    }
  }

  void _handlePhoneState(PhoneStateStatus status, String? number) async {
    try {
      print("Phone State Changed: $status, number: $number");

      // Incoming Call
      if (status == PhoneStateStatus.CALL_INCOMING) {
        print("Incoming Call detected: $number");
        _lastStatus = status;
      }
      // Outgoing Call or In Call
      else if (status == PhoneStateStatus.CALL_STARTED) {
         print("Call Started: $number");
         _lastStatus = status;
      }
      // Call Ended - Show overlay immediately
      else if (status == PhoneStateStatus.CALL_ENDED) {
         print("📞 Call Ended detected in Flutter! Number: $number");
         // Show overlay directly from Flutter side
         await _showOverlay("Call ended", number: number ?? "Unknown");
         _lastStatus = status;
      }
    } catch (e) {
      print("Error in _handlePhoneState: $e");
    }
  }

  static const platform = MethodChannel('com.securescan.securescan/app');

    Future<void> _showOverlay(String message, {bool isFull = true, String? number}) async {
    try {
      print("🔍 Attempting to show system overlay...");

      if (await FlutterOverlayWindow.isPermissionGranted()) {
        try {
          // Close any existing overlay first
          // await FlutterOverlayWindow.closeOverlay();
          
          await FlutterOverlayWindow.showOverlay(
            enableDrag: false,
            overlayTitle: "Call Ended",
            overlayContent: "SecureScan Info",
            flag: OverlayFlag.defaultFlag, // defaultFlag = focusable but allows touch through?
            // On Android 12+, we need explicit flags for safety.
            // OverlayFlag.focusPointer // gives focus to overlay
            visibility: NotificationVisibility.visibilitySecret,
            // positionGravity: PositionGravity.center, // Removed as invalid
            height: WindowSize.matchParent,
            width: WindowSize.matchParent,
            alignment: OverlayAlignment.center,
          );
          
          // Pass data to the overlay via sharing (since arguments support in showOverlay is limited/async)
          // Actually, showOverlay doesn't take 'arguments' map directly in all versions, 
          // let's use shareData which is the standard way for this plugin.
           await FlutterOverlayWindow.shareData({
             'status': 'ended', 
             'number': number ?? 'Unknown'
           });
           
          print("✅ System overlay command sent");
        } catch (e) {
          print("❌ Failed to launch system overlay: $e");
        }
      } else {
        print("⚠️ Overlay permission NOT granted.");
        // Optional: request permission again or navigate to settings
        // await FlutterOverlayWindow.requestPermission();
      }

    } catch (e) {
      print("❌ ERROR showing overlay: $e");
    }
  }
}
