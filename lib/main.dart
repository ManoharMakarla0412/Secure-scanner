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
import 'package:securescan/widgets/call_overlay_widget.dart';
import 'app.dart';

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

  // Enable Google Fonts runtime fetching
  GoogleFonts.config.allowRuntimeFetching = true;

  await MobileAds.instance.initialize();
  await SecureScanThemeController.instance.init();
  await CallManager().init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) => runApp(RestartWidget(child: const SecureScanApp())));
}

/// Entry point for OverlayActivity - shows the after-call overlay screen
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Fonts
  GoogleFonts.config.allowRuntimeFetching = true;
  
  // Initialize ads for the overlay
  MobileAds.instance.initialize();
  
  // Run the overlay widget
  runApp(const CallOverlayWidget());
}

// AdMOB UNIT IDS
// ... (comments kept)
