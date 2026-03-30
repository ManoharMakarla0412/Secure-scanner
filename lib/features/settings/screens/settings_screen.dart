// settings_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:securescan/themes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:securescan/services/language_service.dart';
import 'package:securescan/l10n/app_localizations.dart';
import 'package:securescan/features/settings/screens/permissions_screen.dart';
import 'package:securescan/services/ad_manager.dart';
import 'package:securescan/widgets/banner_ad_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedTheme = 'System Mode';
  final List<String> themeModes = ['Light', 'Dark', 'System Mode'];

  static const _primaryBlue = Color(0xFF0A66FF);

  // Ad Unit IDs managed in AdManager

  @override
  void initState() {
    super.initState();

    selectedTheme = SecureScanThemeController.themeModeToString(
      SecureScanThemeController.instance.themeModeNotifier.value,
    );

    SecureScanThemeController.instance.themeModeNotifier.addListener(
      _listenThemeChanges,
    );

    // Show interstitial ad when entering settings
    AdManager.instance.showInterstitialAd();
  }


  void _listenThemeChanges() {
    setState(() {
      selectedTheme = SecureScanThemeController.themeModeToString(
        SecureScanThemeController.instance.themeModeNotifier.value,
      );
    });
  }

  @override
  void dispose() {
    SecureScanThemeController.instance.themeModeNotifier.removeListener(
      _listenThemeChanges,
    );
    super.dispose();
  }

  // Ad loading handled by BannerAdWidget

  Future<void> _changeTheme(String mode) async {
    await SecureScanThemeController.instance.setTheme(mode);
    setState(() => selectedTheme = mode);
    
    // Show interstitial after theme change
    AdManager.instance.showInterstitialAd();

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.themeSetTo(_translateThemeMode(context, mode))),
        backgroundColor: _primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _translateThemeMode(BuildContext context, String mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case 'Light':
        return l10n.light;
      case 'Dark':
        return l10n.dark;
      case 'System Mode':
        return l10n.systemMode;
      default:
        return mode;
    }
  }

  double _tileHeight(BuildContext context) {
    return (MediaQuery.of(context).size.height * 0.08).clamp(56.0, 90.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final tileHeight = _tileHeight(context);
    final l10n = AppLocalizations.of(context)!;


    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          l10n.settingsTitle,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
          const SizedBox(height: 10),

          // THEME DROPDOWN TILE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: tileHeight,
              decoration: _tileDecoration(isDark),
              child: Row(
                children: [
                  _tileIcon(FontAwesomeIcons.circleHalfStroke, isDark),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedTheme,
                          dropdownColor: isDark ? Colors.black : Colors.white,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          items: themeModes
                              .map(
                                (mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(_translateThemeMode(context, mode)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => v != null ? _changeTheme(v) : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🌐 LANGUAGE DROPDOWN TILE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ValueListenableBuilder<Locale>(
              valueListenable: LanguageController.instance.localeNotifier,
              builder: (context, locale, _) {
                return Container(
                  height: tileHeight,
                  decoration: _tileDecoration(isDark),
                  child: Row(
                    children: [
                      _tileIcon(FontAwesomeIcons.language, isDark),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: locale.languageCode,
                              dropdownColor: isDark ? Colors.black : Colors.white,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  LanguageController.instance.setLanguage(newValue);
                                  // Show interstitial after language change
                                  AdManager.instance.showInterstitialAd();
                                }
                              },
                              items: supportedLanguages.map<DropdownMenuItem<String>>((LanguageModel lang) {
                                return DropdownMenuItem<String>(
                                  value: lang.code,
                                  child: Row(
                                    children: [
                                      Text(lang.flag),
                                      const SizedBox(width: 8),
                                      Text("${lang.name} (${lang.nativeName})"),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildSectionHeader(l10n.permissionsTitle),
          _buildSettingsTile(
            icon: FontAwesomeIcons.shieldHalved,
            title: l10n.permissionsTitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PermissionsScreen()),
              );
            },
          ),
          
          _buildSectionHeader(l10n.appInfoSupport),
          _buildSettingsTile(
            icon: FontAwesomeIcons.circleInfo,
            title: l10n.appInfoSupport,
            onTap: () => _openUrl(
                'https://play.google.com/store/apps/details?id=com.securescan.securescan'),
          ),

          _buildSectionHeader("Legal"),
          _buildSettingsTile(
            icon: FontAwesomeIcons.userShield,
            title: l10n.privacyPolicy,
            onTap: () => _openUrl('https://nanogear.in/privacy'),
          ),
          _buildSettingsTile(
            icon: FontAwesomeIcons.lock,
            title: l10n.termsConditions,
            onTap: () => _openUrl('https://nanogear.in/terms'),
          ),


          const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                l10n.copyright,
                style: textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
      bottomNavigationBar: SafeArea(child: BannerAdWidget(adSize: AdSize.fullBanner)),
    );
  }

  Future<void> _openUrl(String url) async {
    // Show interstitial before opening external URL
    await AdManager.instance.showInterstitialAd();
    
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }


  Widget _buildSectionHeader(String title) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: SecureScanTheme.accentBlue,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: _tileHeight(context),
          decoration: _tileDecoration(isDark),
          child: Row(
            children: [
              _tileIcon(icon, isDark),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileIcon(IconData icon, bool isDark) {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF4F4F4),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
      ),
      child: Center(child: Icon(icon, color: _primaryBlue, size: 18)),
    );
  }

  BoxDecoration _tileDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? Colors.black26 : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? Colors.white24 : const Color(0xFFC0C0C0),
      ),
    );
  }
}

