import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:flutter/services.dart';

/// CallManager handles phone permissions and call state tracking.
/// The actual overlay is shown by native OverlayActivity (launched from CallReceiver).
/// This class only handles permissions and optional Flutter-side call tracking.
class CallManager {
  static final CallManager _instance = CallManager._();
  factory CallManager() => _instance;
  CallManager._();

  StreamSubscription<PhoneState>? _subscription;
  bool _isInitialized = false;

  static const platform = MethodChannel('com.securescan.securescan/app');

  Future<void> init() async {
    if (_isInitialized) {
      print("⚠️ CallManager already initialized");
      return;
    }
    _isInitialized = true;
    
    try {
      await _requestPermissions();
      
      // Register the native CallReceiver (handles overlay via OverlayActivity)
      try {
        await platform.invokeMethod('registerCallReceiver');
        print("✅ CallReceiver registered successfully");
      } catch (e) {
        print("⚠️ Failed to register CallReceiver: $e");
      }
      
      // Optional: Listen to phone state for logging/analytics
      _subscription = PhoneState.stream.listen((event) {
        print("📱 Phone State: ${event.status}, number: ${event.number}");
      });
      
      print("✅ CallManager initialized successfully");
    } catch (e) {
      print("Error initializing CallManager: $e");
    }
  }

  Future<void> _requestPermissions() async {
    // Request phone permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.contacts,
      Permission.notification,
    ].request();
    
    print("Permission Statuses: $statuses");
    
    // Request overlay permission (needed for OverlayActivity to show over other apps)
    final overlayStatus = await Permission.systemAlertWindow.status;
    if (!overlayStatus.isGranted) {
      await Permission.systemAlertWindow.request();
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
