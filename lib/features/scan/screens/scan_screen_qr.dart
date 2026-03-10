import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:securescan/l10n/app_localizations.dart';
import 'package:securescan/services/product_service.dart';
import 'package:securescan/features/scan/screens/qr_result_screen.dart';
import 'package:securescan/widgets/app_drawer.dart';

class ScanScreenQR extends StatefulWidget {
  const ScanScreenQR({Key? key}) : super(key: key);

  @override
  State<ScanScreenQR> createState() => _ScanScreenQRState();
}

// -------------------- Result model for navigation --------------------

class QrResultData {
  final String raw;
  final String? format; // e.g., "qrCode", "ean13"
  final String kind; // "url", "phone", "product", "text", "wifi", "vcard", etc.
  final Map<String, dynamic>? data;
  final Uint8List? imageBytes; // captured frame
  final DateTime timestamp;

  const QrResultData({
    required this.raw,
    required this.kind,
    this.format,
    this.data,
    this.imageBytes,
    required this.timestamp,
  });
}

// -------------------- Internal classification --------------------

enum _PayloadKind {
  url,
  phone,
  email,
  wifi,
  vcard,
  calendar,
  geo,
  json,
  text,
  product,
}

class _Payload {
  final _PayloadKind kind;
  final String raw;
  final Map<String, dynamic>? data;
  final String? symbology;
  final DateTime ts;
  final String? imagePath;

  _Payload(this.kind, this.raw, {this.data, this.symbology, this.imagePath, DateTime? ts})
    : ts = ts ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'raw': raw,
    'data': data,
    'symbology': symbology,
    'ts': ts.toIso8601String(),
    'imagePath': imagePath,
  };
}

// -------------------- Screen --------------------

class _ScanScreenQRState extends State<ScanScreenQR>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _brandBlue = Color(0xFF0A66FF);
  static const _prefsKey = 'scan_history';
  static const _historyCap = 200;

  /// Safe Browsing API key (optional)
  String kSafeBrowsingApiKey = '';

  // Product lookup API keys / configs (set these to your keys if you have them)
  // Best coverage: BarcodeLookup (https://www.barcodelookup.com/) — requires API key
  // Fallback: OpenProductFacts / OpenFoodFacts (community datasets)

  // Torch + zoom state
  bool _torchOn = false;
  double _zoom = 1.0; // 1x .. ~4x
  double _baseZoomOnScaleStart = 1.0;

  // Scanner controller
  final MobileScannerController _cameraController = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.unrestricted,
    detectionTimeoutMs: 50,
    returnImage: true,
    autoStart: true,
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
    ],
  );

  final ImagePicker _picker = ImagePicker();

  // Scan state
  String? _lastScanned;
  bool _isProcessing = false;
  Map<String, dynamic>? _parsedJson;
  String? _docsDir;

  // Sweep animation
  late final AnimationController _sweepController;
  late final Animation<double> _sweep;

  // --------- Interstitial Ad Fields ----------
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  int _interstitialLoadAttempts = 0;
  static const int _maxInterstitialLoadAttempts = 3;

  // Test interstitial provided by Google
  static const String _googleTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  // Replace with your production interstitial unit id for release
  static const String _productionInterstitialAdUnitId =
      'ca-app-pub-2961863855425096/8982046403';

  String get _interstitialAdUnitId => kDebugMode
      ? _googleTestInterstitialAdUnitId
      : _productionInterstitialAdUnitId;             

  // --------- Banner Ad Fields ----------
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  int _bannerLoadAttempts = 0;
  static const int _maxBannerLoadAttempts = 3;

  // Test banner provided by Google
  static const String _googleTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  // Replace with your production banner id
  static const String _productionBannerAdUnitId =
      'ca-app-pub-2961863855425096/5968213716';

  String get _bannerAdUnitId =>
      kDebugMode ? _googleTestBannerAdUnitId : _productionBannerAdUnitId;

  @override
  void initState() {
    super.initState();

    // Log screen view to Firebase Analytics
    FirebaseAnalytics.instance.logScreenView(screenName: 'ScanScreenQR');

    // Initialize docs dir for faster image saving in background
    getApplicationDocumentsDirectory().then((dir) => _docsDir = dir.path);

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _sweep = CurvedAnimation(parent: _sweepController, curve: Curves.easeInOut);

    // load ads
    _loadInterstitial();
    _loadBannerAd();

    // Request camera permission — autoStart: true handles camera initialization
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final status = await Permission.camera.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          _showIssueDialog(
            AppLocalizations.of(context)!.cameraPermissionRequired,
            actionText: AppLocalizations.of(context)!.openSettings,
            onAction: () => openAppSettings(),
          );
          return;
        }
        // autoStart: true handles camera initialization
      } catch (e) {
        debugPrint('Camera start failed: $e');
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!_cameraController.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _cameraController.stop();
        break;
      case AppLifecycleState.resumed:
        _lastScanned = null; // Allow re-scanning the same code after returning
        _cameraController.start();
        break;
      case AppLifecycleState.inactive:
        // Keep camera running on inactive (e.g. notification shade) to avoid black screen
        break;
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sweepController.dispose();
    _cameraController.dispose();

    _interstitialAd?.dispose();
    _bannerAd?.dispose();

    super.dispose();
  }

  // -------------------- Interstitial handling --------------------

  void _loadInterstitial() {
    // dispose previous if any
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialReady = false;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialLoadAttempts = 0;
          _interstitialAd = ad;
          _isInterstitialReady = true;

          // set full screen content callbacks
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdShowedFullScreenContent: (ad) =>
                    debugPrint('[Ads] Interstitial shown.'),
                onAdDismissedFullScreenContent: (ad) {
                  debugPrint('[Ads] Interstitial dismissed.');
                  // dispose and preload next
                  ad.dispose();
                  _interstitialAd = null;
                  _isInterstitialReady = false;
                  _loadInterstitial();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  debugPrint('[Ads] Interstitial failed to show: $error');
                  ad.dispose();
                  _interstitialAd = null;
                  _isInterstitialReady = false;
                  _loadInterstitial();
                },
              );

          debugPrint('[Ads] Interstitial loaded.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialLoadAttempts += 1;
          _isInterstitialReady = false;
          debugPrint(
            '[Ads] Interstitial failed to load: $error (attempt $_interstitialLoadAttempts)',
          );
          if (_interstitialLoadAttempts <= _maxInterstitialLoadAttempts) {
            final backoff = Duration(
              seconds: 1 << (_interstitialLoadAttempts - 1),
            );
            Future.delayed(backoff, _loadInterstitial);
          } else {
            debugPrint(
              '[Ads] Interstitial: giving up after $_interstitialLoadAttempts attempts.',
            );
          }
        },
      ),
    );
  }

  Future<void> _showInterstitialThenNavigate(QrResultData result) async {
    // Log scan event to Firebase Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'scan_success',
      parameters: {'type': result.kind, 'format': result.format ?? 'unknown'},
    );

    if (_isInterstitialReady && _interstitialAd != null) {
      try {
        _interstitialAd!.show();

        // Wait for dismissal (poll for _isInterstitialReady becoming false and ad being null)
        final completer = Completer<void>();
        final timeout = Timer(const Duration(seconds: 10), () {
          if (!completer.isCompleted) completer.complete();
        });

        Timer.periodic(const Duration(milliseconds: 300), (timer) {
          if (!mounted) {
            if (!completer.isCompleted) completer.complete();
            timer.cancel();
            return;
          }
          if (!_isInterstitialReady && _interstitialAd == null) {
            if (!completer.isCompleted) completer.complete();
            timer.cancel();
          }
        });

        await completer.future;
        timeout.cancel();

        if (!mounted) return;
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => QrResultScreen(result: result)),
        );
      } catch (e) {
        debugPrint(
          '[Ads] Error showing interstitial: $e — navigating immediately.',
        );
        if (!mounted) return;
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => QrResultScreen(result: result)),
        );
      }
    } else {
      // No interstitial ready — fall back to immediate navigation
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QrResultScreen(result: result)),
      );
    }
  }

  // -------------------- Banner handling --------------------

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isBannerAdReady = true;
            _bannerLoadAttempts = 0;
          });
          debugPrint('[Ads] Banner loaded.');
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          _isBannerAdReady = false;
          _bannerLoadAttempts += 1;
          debugPrint(
            '[Ads] Banner failed to load: $error (attempt $_bannerLoadAttempts)',
          );
          if (_bannerLoadAttempts <= _maxBannerLoadAttempts) {
            final delaySeconds = 1 << (_bannerLoadAttempts - 1);
            Future.delayed(Duration(seconds: delaySeconds), _loadBannerAd);
          }
        },
      ),
    );

    _bannerAd!.load();
  }

  // -------------------- Detect & handle --------------------

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    setState(() => _isProcessing = true);

    final picked = capture.barcodes.first;
    // Capture the frame image returned by mobile_scanner
    final imageBytes = capture.image;

    if (!mounted) {
      _isProcessing = false;
      return;
    }

    try {
      // Proceed immediately with normal flow
      await _handleBarcode(picked, imageBytes);
    } catch (e) {
      debugPrint('[Scanner] Error in _handleBarcode: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
      } else {
        _isProcessing = false;
      }
    }
  }

  void _applyZoom() {
    // _zoom is UI value in range [1.0, 4.0]
    final normalized = ((_zoom - 1.0) / 3.0).clamp(0.0, 1.0);
    _cameraController.setZoomScale(normalized);
  }


  Future<void> _handleBarcode(Barcode barcode, Uint8List? imageBytes) async {
    final raw = barcode.rawValue;
    if (raw == null) return;

    if (raw == _lastScanned) return;

    setState(() {
      _lastScanned = raw;
      _parsedJson = null;
    });

    // Capture image bytes in a local variable immediately so a subsequent
    // detection callback cannot overwrite them before navigation completes.
    final Uint8List? capturedImage = imageBytes;

    // Try parsing JSON (for QR payloads)
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _parsedJson = decoded;
      }
    } catch (_) {
      _parsedJson = null;
    }

    // Optimize speed: Generate image path and start saving in background
    String? savedImagePath;
    if (capturedImage != null && _docsDir != null) {
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      savedImagePath = '${_docsDir}/$fileName';
      
      () async {
        try {
          final file = File(savedImagePath!);
          await file.writeAsBytes(capturedImage);
          final payload = _classifyPayload(raw, symbology: barcode.format.name, imagePath: savedImagePath);
          await _saveScan(payload);
        } catch (e) {
          debugPrint('[History] Async background save failed: $e');
        }
      }();
    } else if (_docsDir == null) {
      getApplicationDocumentsDirectory().then((dir) => _docsDir = dir.path);
    }

    final payload = _classifyPayload(raw, symbology: barcode.format.name, imagePath: savedImagePath);

    // Prepare result — use the local capturedImage.
    // We DON'T fetch product info here anymore to keep scanning instant.
    // QrResultScreen will handle the fetch asynchronously.
    final result = QrResultData(
      raw: payload.raw,
      kind: payload.kind.name,
      format: payload.symbology,
      data: payload.data,
      imageBytes: capturedImage,
      timestamp: payload.ts,
    );

    // --- [NEW] Mock Security Check for Risky URLs ---
    if (payload.kind == _PayloadKind.url) {
      final isRisky = raw.contains('bit.ly') ||
          raw.contains('t.co') ||
          raw.contains('tinyurl.com') ||
          raw.contains('goo.gl');
      if (isRisky) {
        await _showIssueDialog(
          'Security Warning: This shortened URL might lead to a suspicious website. Please scan with caution.',
        );
      }
    }

    // --- show interstitial (if ready) and then navigate ---
    await _showInterstitialThenNavigate(result);

    // Unblock detection pipeline only after navigation is complete
    setState(() => _isProcessing = false);
  }

  // --- [NEW] Issue Dialog with Black Screen Background ---
  Future<void> _showIssueDialog(
    String message, {
    String? actionText,
    VoidCallback? onAction,
  }) async {
    if (!mounted) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent, // No black screen/overlay
      barrierDismissible: true,
      barrierLabel: 'Scan Issue',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 40,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SCANNING ISSUE',
                        style: GoogleFonts.outfit(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black54,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (actionText != null && onAction != null) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onAction();
                            },
                            child: Text(
                              actionText.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white60 : Colors.black54,
                            side: BorderSide(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            AppLocalizations.of(context)!.close.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Scan from gallery
  Future<void> _scanFromGallery() async {
    if (_isProcessing) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isProcessing = true);

    try {
      final capture = await _cameraController.analyzeImage(picked.path);

      if (capture == null || capture.barcodes.isEmpty) {
        if (mounted) {
          _showIssueDialog(AppLocalizations.of(context)!.noCodeFound);
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Use frame image from capture if present, otherwise fallback to file bytes
      Uint8List? frameBytes = capture.image;
      frameBytes ??= await picked.readAsBytes();

      final barcode = capture.barcodes.first;
      await _handleBarcode(barcode, frameBytes);
    } catch (e) {
      // if (mounted) {
      //   _showIssueDialog(AppLocalizations.of(context)!.failedToScan(e.toString()));
      // }
      setState(() => _isProcessing = false);
    }
  }

  // -------------------- Classification --------------------

  static final _urlRegex = RegExp(
    r'^(https?:\/\/)[^\s]+$',
    caseSensitive: false,
  );
  static final _phoneRegex = RegExp(r'^\+?[0-9]{6,15}$');
  static final _geoRegex = RegExp(
    r'^(?:geo:)?\s*(-?\d{1,2}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)(?:,.*)?$',
    caseSensitive: false,
  );

  _Payload _classifyPayload(String raw, {String? symbology, String? imagePath}) {
    final s = raw.trim();
    final sym = (symbology ?? '').toLowerCase();

    // Isbn / Product (from Format)
    if (sym.contains('ean') || sym.contains('upc') || sym.contains('isbn')) {
      final isIsbn = sym.contains('isbn');
      final code = s;
      return _Payload(
        _PayloadKind.product,
        s,
        symbology: symbology,
        data: {'code': code, 'isIsbn': isIsbn},
        imagePath: imagePath,
      );
    }

    // ----- QR & generic classification -----

    // URL
    if (s.toLowerCase().startsWith('http://') ||
        s.toLowerCase().startsWith('https://')) {
      return _Payload(
        _PayloadKind.url,
        s,
        symbology: symbology,
        imagePath: imagePath,
      );
    }

    // Phone
    if (s.startsWith('tel:')) {
      return _Payload(_PayloadKind.phone, s.substring(4), symbology: symbology, imagePath: imagePath);
    }
    if (_phoneRegex.hasMatch(s)) {
      return _Payload(_PayloadKind.phone, s, symbology: symbology, imagePath: imagePath);
    }

    // Email
    if (s.toLowerCase().startsWith('mailto:')) {
      final addr = s.substring(7);
      return _Payload(
        _PayloadKind.email,
        addr,
        data: {'mailto': s},
        symbology: symbology,
        imagePath: imagePath,
      );
    }
    if (RegExp(r'^[\w\.\-+]+@[\w\.\-]+\.[A-Za-z]{2,}\$').hasMatch(s)) {
      return _Payload(_PayloadKind.email, s, symbology: symbology, imagePath: imagePath);
    }

    // Wi-Fi
    if (s.startsWith('WIFI:')) {
      final parts = <String, String>{};
      for (final seg in s.substring(5).split(';')) {
        if (seg.trim().isEmpty) continue;
        final idx = seg.indexOf(':');
        if (idx == -1) continue;
        parts[seg.substring(0, idx)] = seg.substring(idx + 1);
      }
      return _Payload(
        _PayloadKind.wifi,
        s,
        data: {
          'ssid': parts['S'] ?? '',
          'auth': parts['T'] ?? '',
          'password': parts['P'] ?? '',
          'hidden': parts['H'] == 'true',
        },
        symbology: symbology,
        imagePath: imagePath,
      );
    }

    // vCard
    if (s.contains('BEGIN:VCARD')) {
      return _Payload(_PayloadKind.vcard, s, symbology: symbology, imagePath: imagePath);
    }

    // Calendar
    if (s.contains('BEGIN:VEVENT') || s.contains('BEGIN:VCALENDAR')) {
      return _Payload(_PayloadKind.calendar, s, symbology: symbology, imagePath: imagePath);
    }

    // Geo
    final gm = _geoRegex.firstMatch(s);
    if (gm != null) {
      final lat = double.tryParse(gm.group(1)!);
      final lng = double.tryParse(gm.group(2)!);
      return _Payload(
        _PayloadKind.geo,
        s,
        data: {'lat': lat, 'lng': lng},
        symbology: symbology,
        imagePath: imagePath,
      );
    }

    // JSON
    if (_parsedJson != null) {
      return _Payload(
        _PayloadKind.json,
        s,
        data: _parsedJson,
        symbology: symbology,
        imagePath: imagePath,
      );
    }

    // Plain text
    try {
      return _Payload(_PayloadKind.text, s, symbology: symbology, imagePath: imagePath);
    } catch (_) {
      return _Payload(_PayloadKind.text, s, symbology: symbology, imagePath: imagePath);
    }
  }

  // -------------------- History --------------------

  Future<void> _saveScan(_Payload payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey) ?? <String>[];

      list.add(jsonEncode(payload.toJson()));

      if (list.length > _historyCap) {
        // Prune older items & clean up their image files to prevent storage leak
        final toRemove = list.sublist(0, list.length - _historyCap);
        for (final itemJson in toRemove) {
          try {
            final map = jsonDecode(itemJson);
            final path = map['imagePath']?.toString();
            if (path != null) {
              final file = File(path);
              if (await file.exists()) {
                await file.delete();
              }
            }
          } catch (_) {}
        }
        final pruned = list.sublist(list.length - _historyCap);
        await prefs.setStringList(_prefsKey, pruned);
      } else {
        await prefs.setStringList(_prefsKey, list);
      }
    } catch (_) {
      // ignore
    }
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final double frameW = size.width * 0.86;
    final double frameH = frameW;

    // compute banner height (if ready) to avoid overlaps (approx + margin)
    final double adHeight = _isBannerAdReady && _bannerAd != null
        ? _bannerAd!.size.height.toDouble() + 12
        : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Camera preview with pinch-to-zoom
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (details) {
                _baseZoomOnScaleStart = _zoom;
              },
              onScaleUpdate: (details) {
                if (details.pointerCount < 2) return;
                final newZoom = (_baseZoomOnScaleStart * details.scale)
                    .clamp(1.0, 4.0);
                setState(() {
                  _zoom = newZoom;
                });
                _applyZoom();
              },
              child: MobileScanner(
                controller: _cameraController,
                fit: BoxFit.cover,
                onDetect: _onDetect,
              ),
            ),
          ),

          // Top controls (drawer, flash, gallery, switch camera)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => _roundIconButton(
                      icon: Icons.menu,
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _roundIconButton(
                    icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                    onTap: () async {
                      try {
                        await _cameraController.toggleTorch();
                      } catch (_) {}
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                  const SizedBox(width: 8),
                  _roundIconButton(
                    icon: Icons.photo_library_outlined,
                    onTap: _scanFromGallery,
                  ),
                  const Spacer(),
                  _roundIconButton(
                    icon: Icons.cameraswitch,
                    onTap: () => _cameraController.switchCamera(),
                  ),
                ],
              ),
            ),
          ),
          // Safe Scan overlay (3s animation)

          // Framing + sweep
          Align(
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: frameW,
              height: frameH,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white70, width: 2),
                    ),
                  ),
                  _cornerGuide(top: true, left: true),
                  _cornerGuide(top: true, right: true),
                  _cornerGuide(bottom: true, left: true),
                  _cornerGuide(bottom: true, right: true),
                  AnimatedBuilder(
                    animation: _sweep,
                    builder: (context, _) {
                      final bandH = frameH * 0.42;
                      final y = (_sweep.value * (frameH - bandH));
                      return Positioned(
                        left: 0,
                        right: 0,
                        top: y,
                        child: IgnorePointer(
                          child: Container(
                            height: bandH,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _brandBlue.withValues(alpha: 0.55),
                                  _brandBlue.withValues(alpha: 0.30),
                                  _brandBlue.withValues(alpha: 0.10),
                                  Colors.transparent,
                                ],
                                stops: const [0, 0.45, 0.8, 1],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Hint text (lifted up by banner height to avoid overlap)
          Positioned(
            left: 0,
            right: 0,
            bottom: 130 + (adHeight > 0 ? adHeight - 12 : 0),
            child: const _HintBubble(text: 'Point camera at a code to scan'),
          ),

          // Zoom slider (also lifted)
          Positioned(
            left: 16,
            right: 16,
            bottom: 80 + (adHeight > 0 ? adHeight - 12 : 0),
            child: Row(
              children: [
                Icon(
                  Icons.zoom_out,
                  color: _zoom > 1.0 ? Colors.white : Colors.white38,
                  size: 20,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayColor: Colors.white24,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      min: 1.0,
                      max: 4.0,
                      value: _zoom,
                      onChanged: (value) {
                        setState(() {
                          _zoom = value;
                        });
                        _applyZoom();
                      },
                    ),
                  ),
                ),
                Icon(
                  Icons.zoom_in,
                  color: _zoom < 4.0 ? Colors.white : Colors.white38,
                  size: 20,
                ),
              ],
            ),
          ),

          // Banner Ad at bottom (shows only when loaded)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _isBannerAdReady && _bannerAd != null
                ? Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        height: _bannerAd!.size.height.toDouble(),
                        child: Center(
                          child: SizedBox(
                            width: _bannerAd!.size.width.toDouble(),
                            height: _bannerAd!.size.height.toDouble(),
                            child: AdWidget(ad: _bannerAd!),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // -------------------- Widget helpers --------------------

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _cornerGuide({
    bool top = false,
    bool left = false,
    bool right = false,
    bool bottom = false,
  }) {
    const double len = 28;
    const double thick = 5;
    return Positioned(
      top: top ? 0 : null,
      bottom: bottom ? 0 : null,
      left: left ? 0 : null,
      right: right ? 0 : null,
      child: CustomPaint(
        size: const Size(len, len),
        painter: _CornerPainter(
          color: _brandBlue,
          thickness: thick,
          top: top,
          left: left,
          right: right,
          bottom: bottom,
        ),
      ),
    );
  }
}

class _HintBubble extends StatelessWidget {
  final String text;
  const _HintBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

// Painter for blue corner brackets
class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top, left, right, bottom;

  _CornerPainter({
    required this.color,
    required this.thickness,
    required this.top,
    required this.left,
    required this.right,
    required this.bottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height * 0.6);
      path.lineTo(0, 0);
      path.lineTo(size.width * 0.6, 0);
    } else if (top && right) {
      path.moveTo(size.width * 0.4, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height * 0.6);
    } else if (bottom && left) {
      path.moveTo(0, size.height * 0.4);
      path.lineTo(0, size.height);
      path.lineTo(size.width * 0.6, size.height);
    } else if (bottom && right) {
      path.moveTo(size.width * 0.4, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height * 0.4);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) =>
      old.color != color || old.thickness != thickness;
}
