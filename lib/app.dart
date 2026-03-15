// app.dart
import 'package:flutter/material.dart';
import 'package:securescan/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:securescan/features/onboarding.screens/onboarding_screen.dart';
import 'package:securescan/features/onboarding.screens/initial_permissions_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:securescan/services/language_service.dart';
import 'package:securescan/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/bottom_nav_shell.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SecureScanApp extends StatelessWidget {
  const SecureScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SecureScanThemeController.instance.themeModeNotifier,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LanguageController.instance.localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'QR & Barcode Scanner Generator',
              theme: SecureScanTheme.lightTheme,
              darkTheme: SecureScanTheme.darkTheme,
              themeMode: mode,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const _LaunchDecider(),
            );
          },
        );
      },
    );
  }
}

/// Decides whether to show onboarding or jump to the main app based on
/// whether any SharedPreferences exist (e.g., scan history already saved).
class _LaunchDecider extends StatefulWidget {
  const _LaunchDecider({Key? key}) : super(key: key);

  @override
  State<_LaunchDecider> createState() => _LaunchDeciderState();
}

class _LaunchDeciderState extends State<_LaunchDecider> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Explicitly check for onboarding and permissions status
    final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
    final cameraStatus = await Permission.camera.status;

    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!onboardingDone) {
        // Users who haven't finished onboarding or seen permissions screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else if (!cameraStatus.isGranted) {
        // Finished the slides but skipped/denied camera which we want to enforce
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InitialPermissionsScreen()),
        );
      } else {
        // Ready for full app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BottomNavShell()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lightweight splash while we check prefs
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}