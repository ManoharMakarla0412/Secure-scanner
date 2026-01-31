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

  StreamSubscription<PhoneState>? _subscription;
  PhoneStateStatus _lastStatus = PhoneStateStatus.NOTHING;
  String? _lastNumber;
  bool _wasInCall = false; // Track if we were actually in a call
  bool _isInitialized = false;

  Future<void> init() async {
    // Prevent multiple initializations
    if (_isInitialized) {
      print("⚠️ CallManager already initialized");
      return;
    }
    _isInitialized = true;
    
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
          print("📞 Overlay trigger received from native: status=$status, number=$number");
          
          // Only show overlay if we were in a call
          if (status == 'ended') {
            await _showOverlay("Call ended", number: number);
          }
        }
      });
      print("✅ Method channel handler registered");
      
      _subscription = PhoneState.stream.listen((event) {
        _handlePhoneState(event.status, event.number);
      });
      
      print("✅ CallManager initialized successfully");
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
    ].request();
    
    print("Permission Statuses: $statuses");
    
    // Check and request System Alert Window (Overlay) permission
    final overlayStatus = await Permission.systemAlertWindow.status;
    if (!overlayStatus.isGranted) {
      final status = await Permission.systemAlertWindow.request();
      if (!status.isGranted) {
        print("⚠️ Overlay permission not granted");
      }
    }
  }

  void _handlePhoneState(PhoneStateStatus status, String? number) async {
    try {
      print("📱 Phone State Changed: $status, number: $number, wasInCall: $_wasInCall, lastStatus: $_lastStatus");

      // Incoming Call - mark that we're in a call
      if (status == PhoneStateStatus.CALL_INCOMING) {
        print("📞 Incoming Call detected: $number");
        _wasInCall = true;
        _lastNumber = number;
        _lastStatus = status;
      }
      // Call Started (answered or outgoing) - mark that we're in a call
      else if (status == PhoneStateStatus.CALL_STARTED) {
        print("📞 Call Started: $number");
        _wasInCall = true;
        _lastNumber = number ?? _lastNumber;
        _lastStatus = status;
      }
      // Call Ended - Show overlay for all valid call scenarios
      else if (status == PhoneStateStatus.CALL_ENDED) {
        print("📞 Call Ended detected! wasInCall: $_wasInCall, lastStatus: $_lastStatus");
        
        /*
         * Show overlay in these scenarios:
         * 1. Incoming call answered then hung up: INCOMING → STARTED → ENDED
         * 2. Incoming call rejected/missed: INCOMING → ENDED
         * 3. Outgoing call connected then hung up: STARTED → ENDED
         * 4. Any call that was tracked: wasInCall = true
         */
        if (_wasInCall) {
          final displayNumber = number ?? _lastNumber ?? "Unknown";
          print("📞 Showing overlay for ended call. Number: $displayNumber");
          await _showOverlay("Call ended", number: displayNumber);
        } else {
          print("⚠️ Skipping overlay - was not in an active call");
        }
        
        // Reset state
        _wasInCall = false;
        _lastNumber = null;
        _lastStatus = status;
      }
      // NOTHING state - don't reset wasInCall as it can come at various times
      else if (status == PhoneStateStatus.NOTHING) {
        print("📱 Phone state: NOTHING");
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

      // Check if overlay is already active
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        print("⚠️ Overlay already active, closing first...");
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (await FlutterOverlayWindow.isPermissionGranted()) {
        try {
          // Show full screen overlay
          await FlutterOverlayWindow.showOverlay(
            enableDrag: false,
            overlayTitle: "QR Barcode Scanner",
            overlayContent: "Call Ended",
            flag: OverlayFlag.defaultFlag,
            visibility: NotificationVisibility.visibilityPublic,
            positionGravity: PositionGravity.auto,
            height: WindowSize.fullCover,
            width: WindowSize.matchParent,
          );
          
          // Delay to ensure overlay window is ready before sending data
          await Future.delayed(const Duration(milliseconds: 400));
          
          // Pass call data to the overlay widget
          await FlutterOverlayWindow.shareData({
            'status': 'ended', 
            'number': number ?? 'Unknown Number'
          });
           
          print("✅ System overlay shown successfully for number: $number");
        } catch (e) {
          print("❌ Failed to launch system overlay: $e");
        }
      } else {
        print("⚠️ Overlay permission NOT granted. Requesting...");
        await FlutterOverlayWindow.requestPermission();
      }

    } catch (e) {
      print("❌ ERROR showing overlay: $e");
    }
  }
}