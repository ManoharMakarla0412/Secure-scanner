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
      // Call Ended - Only show overlay if we were actually in a call
      else if (status == PhoneStateStatus.CALL_ENDED) {
        print("📞 Call Ended detected! wasInCall: $_wasInCall");
        
        // Only show overlay if we were actually in a call before
        if (_wasInCall && (_lastStatus == PhoneStateStatus.CALL_STARTED || 
            _lastStatus == PhoneStateStatus.CALL_INCOMING)) {
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
      // NOTHING state - reset but don't show overlay
      else if (status == PhoneStateStatus.NOTHING) {
        print("📱 Phone state: NOTHING");
        // Don't reset _wasInCall here as NOTHING can come before CALL_ENDED on some devices
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
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (await FlutterOverlayWindow.isPermissionGranted()) {
        try {
          await FlutterOverlayWindow.showOverlay(
            enableDrag: false,
            overlayTitle: "Call Ended",
            overlayContent: "SecureScan Info",
            flag: OverlayFlag.defaultFlag,
            visibility: NotificationVisibility.visibilitySecret,
            height: WindowSize.matchParent,
            width: WindowSize.matchParent,
            alignment: OverlayAlignment.center,
          );
          
          // Small delay to ensure overlay is ready
          await Future.delayed(const Duration(milliseconds: 200));
          
          // Pass data to the overlay
          await FlutterOverlayWindow.shareData({
            'status': 'ended', 
            'number': number ?? 'Unknown'
          });
           
          print("✅ System overlay shown successfully");
        } catch (e) {
          print("❌ Failed to launch system overlay: $e");
        }
      } else {
        print("⚠️ Overlay permission NOT granted.");
      }

    } catch (e) {
      print("❌ ERROR showing overlay: $e");
    }
  }
}