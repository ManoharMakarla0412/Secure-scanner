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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedTheme = 'System Mode';
  final List<String> themeModes = ['Light', 'Dark', 'System Mode'];

  static const _primaryBlue = Color(0xFF0A66FF);

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  static const _googleTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const _productionBannerAdUnitId =
      'ca-app-pub-2961863855425096/5968213716';

  String get _adUnitId =>
      kDebugMode ? _googleTestBannerAdUnitId : _productionBannerAdUnitId;

  int _loadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  // ── Facebook Mediation test ──────────────────────────────────────────────
  // Official test ad-unit provided by Google for mediation adapter testing.
  // Swap to your real unit ID when going to production.
  static const _fbMediationTestAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // uses test mode to exercise adapter

  bool _isMediationTesting = false;

  @override
  void initState() {
    super.initState();

    selectedTheme = SecureScanThemeController.themeModeToString(
      SecureScanThemeController.instance.themeModeNotifier.value,
    );

    SecureScanThemeController.instance.themeModeNotifier.addListener(
      _listenThemeChanges,
    );

    _loadBannerAd();
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
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isBannerAdReady = false;
          if (++_loadAttempts <= _maxLoadAttempts) {
            Future.delayed(
              Duration(seconds: 1 << (_loadAttempts - 1)),
              _loadBannerAd,
            );
          }
          setState(() {});
        },
      ),
    )..load();
  }

  Future<void> _changeTheme(String mode) async {
    await SecureScanThemeController.instance.setTheme(mode);
    setState(() => selectedTheme = mode);

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
          _buildSettingsTile(
            icon: FontAwesomeIcons.circleInfo,
            title: l10n.appInfoSupport,
            onTap: () => _openUrl(
                'https://play.google.com/store/apps/details?id=com.securescan.securescan'),
          ),

          // ── Facebook Mediation test tile (debug & release) ───────────────
          _buildMediationTestTile(isDark, textTheme),

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

          // ✅ 50% SPACE FOR AD (RESPONSIVE & SAFE)
          Expanded(
            flex: 5,
            child: _isBannerAdReady && _bannerAd != null
                ? Center(
                    child: SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: _BannerAdWidget(ad: _bannerAd!),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  // ── Facebook Mediation test ──────────────────────────────────────────────
  void _testFacebookMediation() {
    if (_isMediationTesting) return;
    setState(() => _isMediationTesting = true);

    BannerAd? testAd;
    testAd = BannerAd(
      adUnitId: _fbMediationTestAdUnitId,
      size: AdSize.banner,
      // Targeting with a custom keyword to hint the mediation SDK.
      request: const AdRequest(
        extras: {'npa': '1'}, // non-personalized flag for GDPR safety in tests
      ),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          testAd?.dispose();
          setState(() => _isMediationTesting = false);
          _showMediationResult(
            success: true,
            message: '✅ Facebook Mediation loaded successfully!\n\n'
                'Adapter responded and delivered an ad creative.',
          );
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() => _isMediationTesting = false);
          _showMediationResult(
            success: false,
            message: '❌ Mediation failed to load.\n\n'
                'Code: ${error.code}\n'
                'Domain: ${error.domain}\n'
                'Message: ${error.message}',
          );
        },
      ),
    )..load();
  }

  void _showMediationResult({required bool success, required String message}) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: success ? Colors.greenAccent : Colors.redAccent,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              success ? 'Mediation OK' : 'Mediation Error',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF0A66FF))),
          ),
        ],
      ),
    );
  }

  Widget _buildMediationTestTile(bool isDark, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isMediationTesting ? null : _testFacebookMediation,
        child: Container(
          height: _tileHeight(context),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1877F2).withOpacity(0.15)
                : const Color(0xFFE8F0FE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1877F2).withOpacity(0.5),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // Facebook-blue icon panel
              Container(
                width: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2).withOpacity(isDark ? 0.25 : 0.12),
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
                child: Center(
                  child: _isMediationTesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF1877F2),
                            ),
                          ),
                        )
                      : const Icon(
                          FontAwesomeIcons.facebookF,
                          color: Color(0xFF1877F2),
                          size: 18,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _isMediationTesting
                      ? 'Testing FB Mediation…'
                      : 'Test Facebook Mediation',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1877F2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: const Color(0xFF1877F2).withOpacity(0.7),
                ),
              ),
            ],
          ),
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

class _BannerAdWidget extends StatefulWidget {
  final BannerAd ad;

  const _BannerAdWidget({required this.ad});

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  late BannerAd _ad;

  @override
  void initState() {
    super.initState();
    _ad = widget.ad;
  }

  @override
  Widget build(BuildContext context) {
    return AdWidget(ad: _ad);
  }
}