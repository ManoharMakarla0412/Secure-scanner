import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:securescan/features/scan/screens/scan_screen_qr.dart';
import 'package:securescan/themes.dart';
import 'package:securescan/services/call_manager.dart';
import 'package:securescan/widgets/call_overlay_widget.dart'; // Import CallOverlayWidget
import 'package:flutter_overlay_window/flutter_overlay_window.dart'; // Needed for overlay listener
import 'dart:async'; // For StreamController
import 'app.dart';

// Global broadcast controller to handle overlay events safely across widget rebuilds
final StreamController<dynamic> overlayEventController = StreamController<dynamic>.broadcast();
bool _isOverlayListenerInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Send Flutter errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Enable Google Fonts runtime fetching to avoid errors if assets are missing
  GoogleFonts.config.allowRuntimeFetching = true;

  await MobileAds.instance.initialize();
  await SecureScanThemeController.instance.init();
  
  // Close any existing overlay before starting the app
  try {
    final isActive = await FlutterOverlayWindow.isActive();
    if (isActive) {
      print("⚠️ Closing existing overlay on app start");
      await FlutterOverlayWindow.closeOverlay();
    }
  } catch (e) {
    print("Error checking/closing overlay: $e");
  }
  
  await CallManager().init(); // <- Initialize CallManager

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) => runApp(RestartWidget(child: const SecureScanApp())));
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safely initialize the global listener ONCE
  if (!_isOverlayListenerInitialized) {
    try {
      // Convert to broadcast stream to allow multiple listeners if needed
      FlutterOverlayWindow.overlayListener.asBroadcastStream().listen((data) {
        overlayEventController.add(data);
      }, onError: (e) {
        print("Overlay Listener Error: $e");
      });
      _isOverlayListenerInitialized = true;
    } catch (e) {
      print("Failed to listen to overlay stream (already listened?): $e");
    }
  }

  // Run overlay with light theme to match the clean design
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CallOverlayWidget(),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF0A66FF),
      ),
      themeMode: ThemeMode.light,
    ),
  );
}

// AdMOB UNIT IDS
// ... (comments kept)
