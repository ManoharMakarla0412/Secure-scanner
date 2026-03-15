import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:securescan/l10n/app_localizations.dart';
import 'package:securescan/services/ad_manager.dart';
import 'package:securescan/widgets/banner_ad_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:securescan/features/generate/screens/generator_screen.dart';
import 'package:securescan/features/scan/screens/qr_result_screen.dart';
import 'package:securescan/widgets/app_drawer.dart';
import 'package:securescan/core/config/secrets.dart';
import 'package:securescan/features/scan/services/scanner_service.dart';
import 'package:securescan/core/enums/qr_type.dart';
import 'package:securescan/core/models/history_item.dart';
import 'package:securescan/core/repositories/history_repository.dart';

class ScanScreenQR extends StatefulWidget {
  const ScanScreenQR({Key? key}) : super(key: key);

  @override
  State<ScanScreenQR> createState() => _ScanScreenQRState();
}

class _ScanScreenQRState extends State<ScanScreenQR>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _brandBlue = Color(0xFF0A66FF);

  // Torch + zoom state
  bool _torchOn = false;
  double _zoom = 1.0; 
  double _baseZoomOnScaleStart = 1.0;

  // Scanner controller
  final MobileScannerController _cameraController = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.unrestricted,
    detectionTimeoutMs: 50,
    returnImage: true,
    autoStart: false,
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
  String? _docsDir;

  // Sweep animation
  late final AnimationController _sweepController;
  late final Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logScreenView(screenName: 'ScanScreenQR');
    
    getApplicationDocumentsDirectory().then((dir) => _docsDir = dir.path);

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _sweep = CurvedAnimation(parent: _sweepController, curve: Curves.easeInOut);

    AdManager.instance.loadInterstitialAd();

    // Request camera permission
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          _showIssueDialog(AppLocalizations.of(context)!.cameraPermissionRequired);
        }
        return;
      }
      await _cameraController.start();
      if (mounted) setState(() {}); 
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
        _lastScanned = null;
        _cameraController.start();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sweepController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    final picked = capture.barcodes.first;
    final imageBytes = capture.image;
    await _handleBarcode(picked, imageBytes);
  }

  Future<void> _handleBarcode(Barcode barcode, Uint8List? imageBytes) async {
    final raw = barcode.rawValue;
    if (raw == null || raw == _lastScanned) return;

    setState(() {
      _lastScanned = raw;
      _isProcessing = true;
    });

    final type = ScannerService.classify(raw, format: barcode.format.name);
    
    // Security check for risky URLs
    if (type == QrType.url) {
      final isRisky = raw.contains('bit.ly') || raw.contains('t.co') || raw.contains('tinyurl.com') || raw.contains('goo.gl');
      if (isRisky) {
        await _showIssueDialog('Security Warning: This shortened URL might lead to a suspicious website. Please scan with caution.');
      }
    }

    String? savedImagePath;
    if (imageBytes != null && _docsDir != null) {
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      savedImagePath = '$_docsDir/$fileName';
      try {
        await File(savedImagePath).writeAsBytes(imageBytes);
      } catch (e) {
        debugPrint('[Scanner] Failed to save image: $e');
      }
    }

    final historyItem = await ScannerService.saveToHistory(
      raw: raw,
      type: type,
      imagePath: savedImagePath,
      imageBytes: imageBytes,
      metadata: {'format': barcode.format.name, ... (barcode.rawValue != null ? {'raw': barcode.rawValue} : {})},
    );

    // analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'scan_success',
      parameters: {'type': type.name, 'format': barcode.format.name},
    );

    await AdManager.instance.showInterstitialAd();
    if (!mounted) return;
    
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QrResultScreen(result: historyItem)),
    );

    setState(() => _isProcessing = false);
  }

  Future<void> _scanFromGallery() async {
    if (_isProcessing) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isProcessing = true);
    try {
      final historyItem = await ScannerService.scanImage(picked.path);
      if (historyItem == null) {
        if (mounted) _showIssueDialog(AppLocalizations.of(context)!.noCodeFound);
        setState(() => _isProcessing = false);
        return;
      }
      
      final frameBytes = await picked.readAsBytes();
      await _handleBarcodeMLKit(historyItem, frameBytes);
    } catch (e) {
      if (mounted) _showIssueDialog(AppLocalizations.of(context)!.failedToScan(e.toString()));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleBarcodeMLKit(HistoryItem historyItem, Uint8List imageBytes) async {
    // This is a helper to handle results from ML Kit scan (gallery)
    // Similar to _handleBarcode but already has history item basics
    final raw = historyItem.value;
    final type = historyItem.type;

    String? savedImagePath;
    if (_docsDir != null) {
      final fileName = 'scan_gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
      savedImagePath = '$_docsDir/$fileName';
      try {
        await File(savedImagePath).writeAsBytes(imageBytes);
      } catch (_) {}
    }

    final finalizedItem = await ScannerService.saveToHistory(
      raw: raw,
      type: type,
      imagePath: savedImagePath,
      imageBytes: imageBytes,
      metadata: historyItem.metadata,
    );

    await AdManager.instance.showInterstitialAd();
    if (!mounted) return;
    
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QrResultScreen(result: finalizedItem)),
    );

    setState(() => _isProcessing = false);
  }

  void _applyZoom() {
    final normalized = ((_zoom - 1.0) / 3.0).clamp(0.0, 1.0);
    _cameraController.setZoomScale(normalized);
  }

  Future<void> _showIssueDialog(String message) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.scanDetail),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double frameW = size.width * 0.86;
    final double frameH = frameW;

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (details) => _baseZoomOnScaleStart = _zoom,
              onScaleUpdate: (details) {
                if (details.pointerCount < 2) return;
                setState(() => _zoom = (_baseZoomOnScaleStart * details.scale).clamp(1.0, 4.0));
                _applyZoom();
              },
              child: MobileScanner(
                controller: _cameraController,
                fit: BoxFit.cover,
                onDetect: _onDetect,
              ),
            ),
          ),
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
                      try { await _cameraController.toggleTorch(); } catch (_) {}
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
          Align(
            alignment: Alignment.center,
            child: SizedBox(
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
                        left: 0, right: 0, top: y,
                        child: IgnorePointer(
                          child: Container(
                            height: bandH,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _brandBlue.withOpacity(0.55),
                                  _brandBlue.withOpacity(0.30),
                                  _brandBlue.withOpacity(0.10),
                                  Colors.transparent,
                                ],
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
          Positioned(
            left: 0, right: 0, bottom: 130,
            child: const _HintBubble(text: 'Point camera at a code to scan'),
          ),
          Positioned(
            left: 16, right: 16, bottom: 80,
            child: Row(
              children: [
                const Icon(Icons.zoom_out, color: Colors.white, size: 20),
                Expanded(
                  child: Slider(
                    min: 1.0, max: 4.0, value: _zoom,
                    onChanged: (value) {
                      setState(() => _zoom = value);
                      _applyZoom();
                    },
                  ),
                ),
                const Icon(Icons.zoom_in, color: Colors.white, size: 20),
              ],
            ),
          ),
          const Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(top: false, child: BannerAdWidget()),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white, size: 22)),
      ),
    );
  }

  Widget _cornerGuide({bool top = false, bool left = false, bool right = false, bool bottom = false}) {
    return Positioned(
      top: top ? 0 : null, bottom: bottom ? 0 : null,
      left: left ? 0 : null, right: right ? 0 : null,
      child: CustomPaint(
        size: const Size(28, 28),
        painter: _CornerPainter(color: _brandBlue, thickness: 5, top: top, left: left, right: right, bottom: bottom),
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
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top, left, right, bottom;
  _CornerPainter({required this.color, required this.thickness, required this.top, required this.left, required this.right, required this.bottom});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = thickness..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    if (top && left) { path.moveTo(0, size.height * 0.6); path.lineTo(0, 0); path.lineTo(size.width * 0.6, 0); }
    else if (top && right) { path.moveTo(size.width * 0.4, 0); path.lineTo(size.width, 0); path.lineTo(size.width, size.height * 0.6); }
    else if (bottom && left) { path.moveTo(0, size.height * 0.4); path.lineTo(0, size.height); path.lineTo(size.width * 0.6, size.height); }
    else if (bottom && right) { path.moveTo(size.width * 0.4, size.height); path.lineTo(size.width, size.height); path.lineTo(size.width, size.height * 0.4); }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => false;
}
