import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phone_state/phone_state.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:securescan/main.dart'; // Import to access overlayEventController

class CallOverlayWidget extends StatefulWidget {
  const CallOverlayWidget({Key? key}) : super(key: key);

  @override
  State<CallOverlayWidget> createState() => _CallOverlayWidgetState();
}

class _CallOverlayWidgetState extends State<CallOverlayWidget> {
  String _message = "Call Ended";
  StreamSubscription<PhoneState>? _phoneStateSubscription;
  StreamSubscription? _overlaySubscription;
  Timer? _autoDismissTimer;
  final GlobalKey _qrKey = GlobalKey();

  String? _phoneNumber;
  String? _contactName;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  
  // Platform channel for app launching
  static const platform = MethodChannel('com.securescan.securescan/app');

  // Use Google's test banner id in debug. Replace with your real id for release.
  static const String _googleTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  // Replace with your real production ad unit id
  static const String _productionBannerAdUnitId =
      'ca-app-pub-2961863855425096/9807705543';

  // Retry logic
  int _loadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  String get _adUnitId =>
      kDebugMode ? _googleTestBannerAdUnitId : _productionBannerAdUnitId;

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('[Ads] Banner loaded.');
          if (mounted) {
            setState(() {
              _isBannerAdReady = true;
              _loadAttempts = 0;
            });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          _isBannerAdReady = false;
          _loadAttempts += 1;
          debugPrint('[Ads] Banner failed to load: $error (attempt $_loadAttempts)');
          if (_loadAttempts <= _maxLoadAttempts) {
            final delaySeconds = 1 << (_loadAttempts - 1);
            Timer(Duration(seconds: delaySeconds), _loadBannerAd);
          }
          if (mounted) setState(() {});
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void initState() {
    super.initState();
    _message = "Call Ended";
    _phoneNumber = "Unknown Number";
    _contactName = null;
    
    _loadBannerAd();
    _initOverlayListener();
    
    try {
      FirebaseAnalytics.instance.logScreenView(screenName: 'CallOverlayScreen');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseRouteArgs();
  }

  void _parseRouteArgs() {
    try {
      final route = ModalRoute.of(context)?.settings.name;
      if (route != null) {
        final uri = Uri.parse(route);
        if (uri.path == '/overlay') {
          final status = uri.queryParameters['status'];
          final number = uri.queryParameters['number'];
          
          if (status == 'ended') {
            setState(() {
              _message = "Call Ended";
              if (number != null && number != 'null' && number != 'Unknown') {
                _phoneNumber = number;
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing route args: $e');
    }
  }

  void _initOverlayListener() {
    _overlaySubscription = overlayEventController.stream.listen((data) {
      if (data != null) {
        debugPrint('Overlay received data: $data');
        if (data is Map) {
          final status = data['status'];
          final number = data['number'];
          final name = data['name'];
          
          if (status == 'ended') {
            setState(() {
              _message = "Call Ended";
              _phoneNumber = (number == null || number == 'null')
                  ? "Unknown Number"
                  : number.toString();
              _contactName = (name == null || name == 'null') ? null : name.toString();
            });
          }
        }
      }
    });
  }

  /// Close the overlay
  Future<void> _closeOverlay() async {
    try {
      debugPrint('❌ Closing overlay...');
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('Error closing overlay: $e');
    }
  }

  /// Create Contact QR - Opens the app's QR generator with contact info
  Future<void> _createContactQR() async {
    try {
      debugPrint('📇 Creating Contact QR...');
      await FlutterOverlayWindow.closeOverlay();
      await platform.invokeMethod('openApp', {'route': '/create-qr'});
    } catch (e) {
      debugPrint('Error creating contact QR: $e');
      try {
        await FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
    }
  }

  /// Scan New Code - Opens the app's scanner
  Future<void> _scanNewCode() async {
    try {
      debugPrint('📷 Opening scanner...');
      await FlutterOverlayWindow.closeOverlay();
      await platform.invokeMethod('openApp', {'route': '/'});
    } catch (e) {
      debugPrint('Error opening scanner: $e');
      try {
        await FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _phoneStateSubscription?.cancel();
    _overlaySubscription?.cancel();
    _autoDismissTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size for full screen coverage
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final statusBarHeight = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    
    return Material(
      type: MaterialType.canvas,
      color: Colors.white,
      child: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Status bar spacer - accounts for notch/status bar
              SizedBox(height: statusBarHeight > 0 ? statusBarHeight : 32),
              
              // Top Header Bar
              _buildHeader(),
              
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    
                    // Call Ended Section
                    _buildCallEndedSection(),
                    
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    _buildActionButtons(),
                    
                    const Spacer(),
                    
                    // Ad Section
                    _buildAdSection(),
                    
                    // Bottom padding for navigation bar
                    SizedBox(height: bottomPadding > 0 ? bottomPadding + 8 : 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close Button
          GestureDetector(
            onTap: _closeOverlay,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: Colors.grey.shade700,
                size: 28,
              ),
            ),
          ),
          
          // SecureScan Branding
          Row(
            children: [
              // QR Code Icon
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0A66FF), width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.qr_code_2,
                  color: const Color(0xFF0A66FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "SecureScan",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0A66FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallEndedSection() {
    String displayName = _contactName ?? _phoneNumber ?? "Unknown";
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Call Ended",
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "with $displayName",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Create Contact QR Button
          Expanded(
            child: _buildActionButton(
              icon: Icons.contact_page_outlined,
              label: "Create\nContact QR",
              onTap: _createContactQR,
            ),
          ),
          const SizedBox(width: 16),
          // Scan New Code Button
          Expanded(
            child: _buildActionButton(
              icon: Icons.camera_alt_outlined,
              label: "Scan\nNew Code",
              onTap: _scanNewCode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A66FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A66FF).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ad Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "Ad",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Ad Container
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF2D3748),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _isBannerAdReady && _bannerAd != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AdWidget(ad: _bannerAd!),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_circle_outline,
                            color: Colors.white.withOpacity(0.6),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Native Video Ad\nPlaceholder",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.6),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
