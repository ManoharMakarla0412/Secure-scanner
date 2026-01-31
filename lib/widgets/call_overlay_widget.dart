import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class CallOverlayWidget extends StatefulWidget {
  const CallOverlayWidget({Key? key}) : super(key: key);

  @override
  State<CallOverlayWidget> createState() => _CallOverlayWidgetState();
}

class _CallOverlayWidgetState extends State<CallOverlayWidget> {
  String _phoneNumber = "Unknown Number";
  String? _contactName;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  int _loadAttempts = 0;
  
  static const platform = MethodChannel('com.securescan.securescan/app');
  static const overlayChannel = MethodChannel('com.securescan.securescan/overlay');
  
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _prodAdUnitId = 'ca-app-pub-2961863855425096/9807705543';
  static const int _maxLoadAttempts = 3;

  String get _adUnitId => kDebugMode ? _testAdUnitId : _prodAdUnitId;

  @override
  void initState() {
    super.initState();
    _initMethodChannel();
    _loadBannerAd();
    _logAnalytics();
  }

  void _logAnalytics() {
    try {
      FirebaseAnalytics.instance.logScreenView(screenName: 'CallOverlayScreen');
    } catch (_) {}
  }

  void _initMethodChannel() {
    // Listen for call data from native OverlayActivity
    overlayChannel.setMethodCallHandler((call) async {
      if (call.method == 'setCallData' && mounted) {
        final args = call.arguments as Map?;
        if (args != null) {
          setState(() {
            final number = args['number'];
            final name = args['name'];
            _phoneNumber = (number == null || number == 'null' || number == 'Unknown')
                ? "Unknown Number"
                : number.toString();
            _contactName = (name == null || name == 'null') ? null : name.toString();
          });
          debugPrint('📞 Received call data: $_phoneNumber');
        }
      }
    });
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isBannerAdReady = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _loadAttempts++;
          if (_loadAttempts <= _maxLoadAttempts) {
            Timer(Duration(seconds: 1 << (_loadAttempts - 1)), _loadBannerAd);
          }
          if (mounted) setState(() => _isBannerAdReady = false);
        },
      ),
    )..load();
  }

  Future<void> _closeOverlay() async {
    try {
      // Finish the OverlayActivity
      await platform.invokeMethod('finishOverlay');
    } catch (e) {
      debugPrint('Error closing: $e');
    }
    // Exit
    SystemNavigator.pop();
  }

  Future<void> _createContactQR() async {
    try {
      await platform.invokeMethod('openApp', {'route': '/create-qr'});
    } catch (e) {
      debugPrint('Error: $e');
    }
    SystemNavigator.pop();
  }

  Future<void> _scanNewCode() async {
    try {
      await platform.invokeMethod('openApp', {'route': '/'});
    } catch (e) {
      debugPrint('Error: $e');
    }
    SystemNavigator.pop();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          width: size.width,
          height: size.height,
          color: Colors.white,
          child: Column(
            children: [
              // Status bar space
              SizedBox(height: padding.top),
              
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildCallEndedSection(),
                      const SizedBox(height: 40),
                      _buildActionButtons(),
                      const SizedBox(height: 40),
                      _buildAdSection(),
                    ],
                  ),
                ),
              ),
              
              // Bottom safe area
              SizedBox(height: padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close Button
          GestureDetector(
            onTap: _closeOverlay,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.close, color: Colors.grey.shade700, size: 24),
            ),
          ),
          // Branding
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A66FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_2, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "QR Barcode Scanner",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "& Generator",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallEndedSection() {
    final displayName = _contactName ?? _phoneNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Call Ended",
          style: GoogleFonts.inter(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "with $displayName",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            icon: Icons.contact_page_outlined,
            label: "Create\nContact QR",
            onTap: _createContactQR,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildButton(
            icon: Icons.camera_alt_outlined,
            label: "Scan\nNew Code",
            onTap: _scanNewCode,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A66FF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A66FF).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            "Ad",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: _isBannerAdReady && _bannerAd != null
              ? AdWidget(ad: _bannerAd!)
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: Colors.white.withOpacity(0.5),
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Video Ad\nPlaceholder",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
