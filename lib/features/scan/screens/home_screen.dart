import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:securescan/core/constants/app_assets.dart';
import 'package:securescan/widgets/app_drawer.dart';

import 'package:securescan/features/generate/screens/generator_screen.dart';
import 'package:securescan/features/scan/screens/scan_screen_qr.dart';
import 'package:securescan/l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:securescan/widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Ad Unit IDs managed in AdManager

  @override
  void initState() {
    super.initState();

    // Log screen view to Firebase Analytics
    FirebaseAnalytics.instance.logScreenView(screenName: 'HomeScreen');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // Ad loading handled by BannerAdWidget

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // If banner not ready, we return a zero-height widget — nothing visible.
    // (Logic moved inside LayoutBuilder)

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: colorScheme.onSurface),
            onPressed: () => Scaffold.of(context).openDrawer(),
            splashRadius: 24,
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.appTitle,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2), // ~2% top spacing
              Expanded(
                flex: 20, // 20% height
                child: PrimaryCTA(
                  label: AppLocalizations.of(context)!.scan,
                  iconPath: AppAssets.scanIcon,
                  width: double.infinity,
                  // height is controlled by Expanded -> tight constraint
                  onTap: () {
                    if (ModalRoute.of(context)?.settings.name == "ScanScreenQR") {
                      return;
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: "ScanScreenQR"),
                        builder: (_) => ScanScreenQR(),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(flex: 2), // ~2% gap
              Expanded(
                flex: 20, // 20% height
                child: PrimaryCTA(
                  label: AppLocalizations.of(context)!.createQr,
                  iconPath: AppAssets.createIcon,
                  width: double.infinity,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreateQRScreen()),
                    );
                  },
                ),
              ),
              const Spacer(flex: 4), // ~4% gap
               // ~2% bottom spacing
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BannerAdWidget(adSize: AdSize.mediumRectangle)),
    );
  }
}

/// Rounded blue CTA with left icon + centered text
class PrimaryCTA extends StatelessWidget {
  const PrimaryCTA({
    required this.label,
    required this.onTap,
    required this.iconPath,
    this.width,
    this.height,
    super.key,
  });

  final String label;
  final String iconPath;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 28,
            spreadRadius: 2,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: SizedBox(
        width: width ?? 187,
        height: height ?? 88,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF0A66FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(iconPath, width: 38, height: 38, fit: BoxFit.contain),
              const SizedBox(width: 12),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  fontSize: 29,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
