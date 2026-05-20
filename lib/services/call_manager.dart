import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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
      _subscription = PhoneState.stream.listen((event) {
        _handlePhoneState(event.status);
      });
    } catch (e, stack) {
      debugPrint("Error initializing CallManager: $e");
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'CallManager init failed');
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.phone, Permission.systemAlertWindow].request();
  }

  void _handlePhoneState(PhoneStateStatus status) async {
    try {
      debugPrint("Phone State Changed: $status");

      // Only handle initial launch on Incoming Call
      if (status == PhoneStateStatus.CALL_INCOMING) {
        final bool isActive = await FlutterOverlayWindow.isActive();
        if (isActive) {
          await FlutterOverlayWindow.shareData("incoming");
        } else {
          await _showOverlay("Incoming Call...", isFull: true);
          await Future.delayed(Duration(milliseconds: 500));
          await FlutterOverlayWindow.shareData("incoming");
        }
      }
      // Outgoing Call (Started but not active yet)
      else if (status == PhoneStateStatus.CALL_STARTED) {
        final bool isActive = await FlutterOverlayWindow.isActive();
        if (!isActive) {
          // Outgoing call -> Show minimized overlay immediately
          await _showOverlay("In Call", isFull: false);
          await Future.delayed(Duration(milliseconds: 500));
          await FlutterOverlayWindow.shareData("outgoing");
        }
        // If already active (was incoming), the OverlayWidget's PhoneState listener will handle resizing
      }
      // All other state changes (Started, Ended) are handled by the Overlay itself
      // to ensure it survives even if the main app is killed.

      _lastStatus = status;
    } catch (e, stack) {
      debugPrint("Error in _handlePhoneState: $e");
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Phone state handling failed');
    }
  }

  Future<void> _showOverlay(String message, {bool isFull = true}) async {
    try {
      final bool isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        return;
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "SecureScan Call Alert",
        overlayContent: "Call Alert",
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: isFull
            ? WindowSize.matchParent
            : 40, // Small bubble for outgoing
        width: isFull ? WindowSize.matchParent : 40,
      );
    } catch (e, stack) {
      debugPrint("Error showing overlay: $e");
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Showing overlay failed');
    }
    // We can't easily pass dynamic arguments to showOverlay in the current plugin version
    // unless we use shareData BEFORE or AFTER logic.
    // The widget can default to "Incoming" or we can use shareData to tell it.

    if (message == "Call Ended") {
      await Future.delayed(Duration(milliseconds: 500));
      await FlutterOverlayWindow.shareData("ended");
    }
  }
}
