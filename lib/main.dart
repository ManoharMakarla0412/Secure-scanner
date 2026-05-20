import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:securescan/themes.dart';
import 'package:securescan/services/language_service.dart';
import 'package:securescan/services/ad_manager.dart';
import 'app.dart';

/// Performance-Optimized main.
/// Moves non-essential initializations out of the startup Blocking pool (Reduce ANR).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Essential initialization (Firebase)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Run secondary initializations in parallel (Non-blocking)
  unawaited(AdManager.instance.init());
  unawaited(SecureScanThemeController.instance.init());
  unawaited(LanguageController.instance.init());

  // Send Flutter errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Enable Google Fonts runtime fetching to avoid errors if assets are missing
  GoogleFonts.config.allowRuntimeFetching = true;

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const SecureScanApp());
}
