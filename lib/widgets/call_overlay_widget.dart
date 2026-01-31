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
  String _message = "";
  StreamSubscription<PhoneState>? _phoneStateSubscription;
  StreamSubscription? _overlaySubscription; // Add overlay subscription
  Timer? _autoDismissTimer;
  final GlobalKey _qrKey = GlobalKey(); // Key for QR code capture

  
  bool _isAdLoaded = false;
  String? _phoneNumber;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  
  // Platform channel for app launching
  static const platform = MethodChannel('com.securescan.securescan/app');

  // Use Google's test banner id in debug. Replace with your real id for release.
  static const String _googleTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  // Replace with your real production ad unit id (kept here for clarity)
  static const String _productionBannerAdUnitId =
      'ca-app-pub-2961863855425096/9807705543';

  // Retry logic
  int _loadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  String get _adUnitId =>
      kDebugMode ? _googleTestBannerAdUnitId : _productionBannerAdUnitId;

  

  void _loadBannerAd() {
    // Clean up any existing ad
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
          debugPrint(
            '[Ads] Banner failed to load: $error (attempt $_loadAttempts)',
          );
          if (_loadAttempts <= _maxLoadAttempts) {
            // Exponential backoff retry
            final delaySeconds = 1 << (_loadAttempts - 1); // 1,2,4
            debugPrint('[Ads] Retrying banner load in $delaySeconds s...');
            Timer(Duration(seconds: delaySeconds), _loadBannerAd);
          } else {
            debugPrint('[Ads] Reached max load attempts. Giving up for now.');
          }
          if (mounted) setState(() {}); // ensure UI hides the ad space
        },
        onAdOpened: (Ad ad) => debugPrint('[Ads] Banner opened.'),
        onAdClosed: (Ad ad) => debugPrint('[Ads] Banner closed.'),
        onAdImpression: (Ad ad) => debugPrint('[Ads] Banner impression.'),
      ),
    );

    _bannerAd!.load();
  }

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _initOverlayListener();
    // Don't listen to phone state here - CallManager handles it
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
    // Listen for data sent via shareData from the GLOBAL controller
    _overlaySubscription = overlayEventController.stream.listen((data) {
      if (data != null) {
        debugPrint('Overlay received data: $data');
        // 'data' is typically the map we shared, or a generic object
        if (data is Map) {
          final status = data['status'];
          final number = data['number'];
          
          if (status == 'ended') {
            setState(() {
              _message = "Call Ended";
              _phoneNumber = (number == null || number == 'null')
                  ? "Unknown"
                  : number.toString();
            });
          }
        }
      }
    });
  }

  void _updateState(String msg, bool maximize) {
    setState(() {
      _message = msg;
    });
    // The native CallManager handles resizing often, but we can enforce it here too
    if (maximize) {
       // Done by manager mostly, but can ensure
    }
  }

  

  Future<void> _shareQRCode() async {
    try {
      // Generate QR code image and share it
      final qrData = "tel:${_phoneNumber ?? 'Unknown'}";
      
      // Create QR image programmatically
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/contact_qr.png');
      
      final imageSize = 300.0;
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      
      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, imageSize, imageSize),
        Paint()..color = Colors.white,
      );
      
      // Draw QR code
      qrPainter.paint(canvas, const Size(300, 300));
      
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(imageSize.toInt(), imageSize.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        await file.writeAsBytes(byteData.buffer.asUint8List());
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Contact QR Code for ${_phoneNumber ?? "Unknown Number"}',
          subject: 'SecureScan Contact QR',
        );
      }
      
      // Close overlay after sharing
      await Future.delayed(const Duration(milliseconds: 500));
      await _closeOverlay();
    } catch (e) {
      debugPrint('Error sharing QR code: $e');
      // Fallback to text-only share
      try {
        await Share.share(
          'Contact: ${_phoneNumber ?? "Unknown Number"}',
          subject: 'SecureScan Contact',
        );
      } catch (_) {}
      await _closeOverlay();
    }
  }
  
  /// Opens the main SecureScan app
  Future<void> _openApp() async {
    try {
      debugPrint('📱 Opening main app...');
      
      // Close overlay first
      await FlutterOverlayWindow.closeOverlay();
      
      // Launch main app via platform channel
      await platform.invokeMethod('openApp', {'route': '/'});
      
    } catch (e) {
      debugPrint('Error opening app: $e');
      // Fallback: try to launch via package
      try {
        await FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
    }
  }
  
  /// Opens the Create QR screen in the main app
  Future<void> _openCreateQR() async {
    try {
      debugPrint('📝 Opening Create QR screen...');
      
      // Close overlay first
      await FlutterOverlayWindow.closeOverlay();
      
      // Launch main app with route to create QR
      await platform.invokeMethod('openApp', {'route': '/create-qr'});
      
    } catch (e) {
      debugPrint('Error opening Create QR: $e');
      // Fallback: just close overlay and open app
      try {
        await FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
    }
  }

  Future<void> _closeOverlay() async {
    try {
      debugPrint('❌ Closing system overlay...');
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('Error closing overlay: $e');
    }
  }

  @override
  void dispose() {
    _phoneStateSubscription?.cancel();
    _overlaySubscription?.cancel(); // Clean up overlay subscription
    _autoDismissTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 Building overlay - message: $_message, number: $_phoneNumber');

    final bool hasData = _message.isNotEmpty || _phoneNumber != null;

    debugPrint('📱 Showing full overlay popup');

    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0E27), // Deep Navy
                Color(0xFF1A1F3A), // Dark Purple Blue
                Color(0xFF0F1629), // Rich Black Blue
              ],
            ),
            borderRadius: BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Header with Close Button
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App Branding
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          Text(
                            "SecureScan",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      // Close Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFEF4444),
                              Color(0xFFDC2626),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => FlutterOverlayWindow.closeOverlay(),
                            borderRadius: BorderRadius.circular(10),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content Area
                Flexible(
                  child: hasData
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Ad Slot Section
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                width: 300,
                                height: 250,
                                child: _isBannerAdReady && _bannerAd != null
                                    ? AdWidget(ad: _bannerAd!)
                                    : Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Ad Loading...",
                                            style: GoogleFonts.inter(
                                              color: Colors.white24,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              _buildProfileInfo(),
                              const SizedBox(height: 24),

                              // Action Buttons
                              _buildActionButtons(),
                            ],
                          ),
                        )
                      : Center(
                          child: Text(
                            "Preparing overlay...",
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _buildProfileInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEF4444).withOpacity(0.8),
                  const Color(0xFFDC2626).withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _message == "Incoming Call" ? Icons.call : Icons.call_end_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                const SizedBox(width: 6),
                Text(
                  _message.isEmpty ? "CALL ENDED" : _message.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Phone Number Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Contact Number:",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white60,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _phoneNumber ?? "Unknown Number",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.3),
            const Color(0xFF1E40AF).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Text(
            "Scan QR Code",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Save this contact to your phone",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 28),
          
          // QR Code with Glow
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.5),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 48,
                  spreadRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: QrImageView(
              data: "tel:${_phoneNumber ?? '0000000000'}",
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Share hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: const Color(0xFF60A5FA),
                ),
                const SizedBox(width: 8),
                Text(
                  "Tap Share button to send this QR code",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF60A5FA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Row with Open App and Share QR buttons
        Row(
          children: [
            // Open App Button
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF22C55E),
                      Color(0xFF16A34A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openApp,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.open_in_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Open App",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Share QR Button
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF2563EB),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _shareQRCode,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.share_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Share QR",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Create Other QR Link
        GestureDetector(
          onTap: _openCreateQR,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_rounded,
                  color: const Color(0xFF60A5FA),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "Create Other QR (Text, URL)",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF60A5FA),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF60A5FA),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdSection() {
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }

    // Placeholder if ad not loaded - Optimized size for popup
    return Container(
      width: double.infinity,
      height: 300, // Reduced height to fit better in popup
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.ad_units_rounded,
                color: Colors.white.withOpacity(0.4),
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Advertisement",
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Loading...",
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }


}

class _OverlayBannerWidget extends StatefulWidget {
  const _OverlayBannerWidget();

  @override
  State<_OverlayBannerWidget> createState() => _OverlayBannerWidgetState();
}

class _OverlayBannerWidgetState extends State<_OverlayBannerWidget> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  int _loadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  static const String _googleTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _productionBannerAdUnitId =
      'ca-app-pub-2961863855425096/5968213716';

  String get _adUnitId =>
      kDebugMode ? _googleTestBannerAdUnitId : _productionBannerAdUnitId;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

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
          if (mounted) {
             setState(() {
              _isBannerAdReady = false;
              _loadAttempts += 1;
             });
          }
          debugPrint(
            '[Ads] Banner failed to load: $error (attempt $_loadAttempts)',
          );
          if (_loadAttempts <= _maxLoadAttempts) {
            final delaySeconds = 1 << (_loadAttempts - 1);
            Timer(Duration(seconds: delaySeconds), _loadBannerAd);
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBannerAdReady && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    return const SizedBox(
       height: 250, 
       width: 300,
       child: Center(child: CircularProgressIndicator(color: Colors.white24)),
    );
  }
}
