// app.dart
import 'package:flutter/material.dart';
import 'package:securescan/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:securescan/features/onboarding.screens/onboarding_screen.dart';
import 'package:securescan/features/generate/screens/generator_screen.dart';
import 'widgets/bottom_nav_shell.dart';
import 'package:securescan/widgets/call_overlay_widget.dart'; // Import overlay

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SecureScanApp extends StatelessWidget {
  const SecureScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SecureScanThemeController.instance.themeModeNotifier,
        builder: (context, mode, _) {

         return  MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'QR & Barcode Scanner Generator',
            theme: SecureScanTheme.lightTheme,
            // 🌞
            darkTheme: SecureScanTheme.darkTheme,
           themeMode: mode, // <- controlled here
           
           onGenerateRoute: (settings) {
             final routeName = settings.name ?? '';
             final uri = Uri.parse(routeName);
             
             // Only handle overlay route if explicitly requested with full path
             if (routeName == '/overlay' || uri.path == '/overlay') {
               // This route should only be used for deep linking, not normal navigation
               // The overlay widget runs in overlayMain(), not in the main app
               print("⚠️ Overlay route requested in main app - redirecting to home");
               return MaterialPageRoute(
                 builder: (context) => BottomNavShell(),
                 settings: settings,
               );
             }
             if (routeName == '/create-qr' || uri.path == '/create-qr') {
               return MaterialPageRoute(
                 builder: (context) => CreateQRScreen(),
                 settings: settings,
               );
             }
             return null; // Fallback to 'routes' or 'home'
           },

           home: const _LaunchDecider(),
          );
        }

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

    // Heuristic:
    // - If *any* keys exist, we assume the user has used the app before.
    // - If you prefer a stricter check, look for your specific keys, e.g.:
    //   prefs.containsKey('scan_history')
    final hasAnyData = prefs.getKeys().isNotEmpty;

    // Ensure navigation happens after first frame
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if we're being opened with a specific route (from overlay)
      final currentRoute = ModalRoute.of(context)?.settings.name;
      
      // Don't redirect if we're showing overlay or create-qr
      if (currentRoute == '/overlay' || currentRoute == '/create-qr') {
        return;
      }
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => hasAnyData ? BottomNavShell() : const OnboardingScreen(),
        ),
      );
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