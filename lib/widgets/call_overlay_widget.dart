import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:securescan/main.dart';

class CallOverlayWidget extends StatefulWidget {
  const CallOverlayWidget({Key? key}) : super(key: key);

  @override
  State<CallOverlayWidget> createState() => _CallOverlayWidgetState();
}

class _CallOverlayWidgetState extends State<CallOverlayWidget> {
  String _phoneNumber = "Unknown Number";
  String? _contactName;
  StreamSubscription? _overlaySubscription;
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
    _initOverlayListener();
    _initMethodChannelListener();
    _loadBannerAd();
    _logAnalytics();
  }

  void _logAnalytics() {
    try {
      FirebaseAnalytics.instance.logScreenView(screenName: 'CallOverlayScreen');
    } catch (_) {}
  }

  void _initMethodChannelListener() {
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
          debugPrint('📞 Received call data via method channel: $_phoneNumber');
        }
      }
    });
  }

  void _initOverlayListener() {
    // Also listen for data from flutter_overlay_window (fallback)
    _overlaySubscription = overlayEventController.stream.listen((data) {
      if (data != null && data is Map && mounted) {
        setState(() {
          final number = data['number'];
          final name = data['name'];
          _phoneNumber = (number == null || number == 'null' || number == 'Unknown')
              ? "Unknown Number"
              : number.toString();
          _contactName = (name == null || name == 'null') ? null : name.toString();
        });
        debugPrint('📞 Received call data via overlay stream: $_phoneNumber');
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
      // Try to close flutter overlay window first
      try {
        await FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
      
      // Also try to finish the activity (if running as OverlayActivity)
      try {
        await platform.invokeMethod('finishActivity');
      } catch (_) {}
      
      // Exit the app if it's the overlay entry point
      SystemNavigator.pop();
    } catch (e) {
      debugPrint('Error closing overlay: $e');
      SystemNavigator.pop();
    }
  }

  Future<void> _createContactQR() async {
    try {
      // Close overlay first
      try { await FlutterOverlayWindow.closeOverlay(); } catch (_) {}
      
      // Open main app with create-qr route
      await platform.invokeMethod('openApp', {'route': '/create-qr'});
      
      // Exit overlay activity
      SystemNavigator.pop();
    } catch (e) {
      debugPrint('Error: $e');
      SystemNavigator.pop();
    }
  }

  Future<void> _scanNewCode() async {
    try {
      // Close overlay first
      try { await FlutterOverlayWindow.closeOverlay(); } catch (_) {}
      
      // Open main app
      await platform.invokeMethod('openApp', {'route': '/'});
      
      // Exit overlay activity
      SystemNavigator.pop();
    } catch (e) {
      debugPrint('Error: $e');
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _overlaySubscription?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        // Extend body behind system bars for true full screen
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: SafeArea(
            top: true,
            bottom: true,
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        
                        // Call Ended Title
                        _buildCallEndedSection(),
                        
                        const SizedBox(height: 40),
                        
                        // Action Buttons
                        _buildActionButtons(),
                        
                        const SizedBox(height: 40),
                        
                        // Ad Section
                        _buildAdSection(),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _closeOverlay,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.close, color: Colors.grey.shade700, size: 24),
              ),
            ),
          ),
          
          // App Branding
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Icon
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
              // App Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "with $displayName",
          style: GoogleFonts.inter(
            fontSize: 17,
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
          child: _ActionButton(
            icon: Icons.contact_page_outlined,
            label: "Create\nContact QR",
            onTap: _createContactQR,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionButton(
            icon: Icons.camera_alt_outlined,
            label: "Scan\nNew Code",
            onTap: _scanNewCode,
          ),
        ),
      ],
    );
  }

  Widget _buildAdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ad Label
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
        // Ad Container
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
              : _AdPlaceholder(),
        ),
      ],
    );
  }
}

// Separate StatelessWidget for Action Button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0A66FF),
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      shadowColor: const Color(0xFF0A66FF).withOpacity(0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

// Separate StatelessWidget for Ad Placeholder
class _AdPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white.withOpacity(0.5),
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Video Ad\nPlaceholder",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.5),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
