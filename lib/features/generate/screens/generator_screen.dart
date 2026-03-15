import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:gal/gal.dart';
import 'package:securescan/l10n/app_localizations.dart';
import 'package:securescan/services/ad_manager.dart';
import 'package:securescan/core/enums/qr_type.dart';
import 'package:securescan/features/generate/controllers/generator_controller.dart';
import 'package:securescan/widgets/banner_ad_widget.dart';
import '../../../themes.dart';

class CreateQRScreen extends StatelessWidget {
  const CreateQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final categories = [
      {'icon': Icons.link, 'type': QrType.url, 'title': l10n.url},
      {'icon': Icons.wifi, 'type': QrType.wifi, 'title': l10n.wifi},
      {'icon': Icons.contact_page, 'type': QrType.contact, 'title': l10n.contact},
      {'icon': Icons.phone, 'type': QrType.phone, 'title': l10n.phone},
      {'icon': Icons.email, 'type': QrType.email, 'title': l10n.email},
      {'icon': Icons.text_snippet, 'type': QrType.text, 'title': l10n.text},
      {'icon': Icons.keyboard, 'type': QrType.text, 'title': "Keyboard Content"},
      {'icon': Icons.calendar_today, 'type': QrType.calendar, 'title': l10n.calendar},
      {'icon': Icons.location_on, 'type': QrType.location, 'title': l10n.location},
    ];

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(l10n.createQrCode),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.15,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          return _CategoryCard(
            icon: item['icon'] as IconData,
            title: item['title'] as String,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateQRCodePage(
                    selectedType: item['type'] as QrType,
                    displayType: item['title'] as String,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _CategoryCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SecureScanTheme.accentBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: SecureScanTheme.accentBlue, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateQRCodePage extends StatefulWidget {
  final QrType selectedType;
  final String displayType;

  const CreateQRCodePage({super.key, required this.selectedType, required this.displayType});

  @override
  State<CreateQRCodePage> createState() => _CreateQRCodePageState();
}

class _CreateQRCodePageState extends State<CreateQRCodePage> {
  late final GeneratorController _controller;
  final GlobalKey _qrKey = GlobalKey();
  final FlutterNativeContactPicker _contactPicker = FlutterNativeContactPicker();

  @override
  void initState() {
    super.initState();
    _controller = GeneratorController(widget.selectedType);
    AdManager.instance.loadInterstitialAd();

    // Auto-paste if it's "Keyboard Content"
    if (widget.displayType == "Keyboard Content") {
      Clipboard.getData(Clipboard.kTextPlain).then((data) {
        if (data != null && data.text != null && mounted) {
          _controller.textController.text = data.text!;
          _controller.validate(AppLocalizations.of(context)!);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickContactFromDevice() async {
    try {
      final Contact? contact = await _contactPicker.selectContact();
      if (contact == null) return;

      final name = contact.fullName ?? '';
      String phone = '';
      if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
        phone = contact.phoneNumbers!.first;
      } else if (contact.selectedPhoneNumber != null && contact.selectedPhoneNumber!.isNotEmpty) {
        phone = contact.selectedPhoneNumber!;
      }

      _controller.nameController.text = name;
      _controller.phoneController.text = phone;
      
      final l10n = AppLocalizations.of(context)!;
      await _controller.generateQRCode(l10n);
    } catch (e) {
      if (e is PlatformException && e.code == 'CANCELED') return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick contact: $e')));
      }
    }
  }

  Future<void> _handleGenerate() async {
    final l10n = AppLocalizations.of(context)!;
    if (_controller.validate(l10n)) {
      await AdManager.instance.showInterstitialAd();
      await _controller.generateQRCode(l10n);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(widget.displayType),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (_controller.isCreated)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: SecureScanTheme.accentBlue),
              onPressed: () => _controller.setIsCreated(false),
              tooltip: "Edit",
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _controller.isCreated
                  ? _buildQRResult(textTheme, colorScheme, l10n)
                  : Column(
                      key: const ValueKey('form'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormFields(textTheme, colorScheme, l10n),
                        const SizedBox(height: 32),
                        _buildCreateButton(l10n),
                        const SizedBox(height: 24),
                        const BannerAdWidget(),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormFields(TextTheme textTheme, ColorScheme colorScheme, AppLocalizations l10n) {
    switch (widget.selectedType) {
      case QrType.url:
        return Column(
          children: [
            _buildTextFieldWithError(
              label: l10n.urlNameWithAst,
              controller: _controller.urlNameController,
              textTheme: textTheme,
              colorScheme: colorScheme,
              error: _controller.urlNameError,
              onChanged: (_) => _controller.validate(l10n),
            ),
            _buildTextFieldWithError(
              label: l10n.urlLinkWithAst,
              controller: _controller.urlLinkController,
              textTheme: textTheme,
              colorScheme: colorScheme,
              error: _controller.urlLinkError,
              keyboard: TextInputType.url,
              onChanged: (_) => _controller.validate(l10n),
            ),
          ],
        );
      case QrType.wifi:
        return Column(
          children: [
            _buildTextFieldWithError(
              label: l10n.wifiNameWithAst,
              controller: _controller.wifiNameController,
              textTheme: textTheme,
              colorScheme: colorScheme,
              error: _controller.wifiNameError,
              onChanged: (_) => _controller.validate(l10n),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _controller.encryptionValue,
              decoration: _inputDecoration(l10n.encryptionTypeWithAst, colorScheme, textTheme),
              items: ["WPA/WPA2", "WEP", "None"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => _controller.setEncryption(v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller.wifiPasswordController,
              obscureText: !_controller.wifiPasswordVisible,
              decoration: _inputDecoration(l10n.password, colorScheme, textTheme).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_controller.wifiPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: _controller.toggleWifiPasswordVisibility,
                ),
              ),
              onChanged: (_) => _controller.validate(l10n),
            ),
            if (_controller.wifiPasswordError != null)
              _errorText(_controller.wifiPasswordError!),
          ],
        );
      case QrType.contact:
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickContactFromDevice,
              icon: const Icon(Icons.contacts_rounded, size: 20),
              label: const Text("Import from Contacts"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                backgroundColor: colorScheme.surface,
                foregroundColor: SecureScanTheme.accentBlue,
                elevation: 0,
                side: BorderSide(color: SecureScanTheme.accentBlue.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextFieldWithError(
              label: l10n.nameWithAst,
              controller: _controller.nameController,
              textTheme: textTheme,
              colorScheme: colorScheme,
              error: _controller.nameError,
              onChanged: (_) => _controller.validate(l10n),
            ),
            _buildTextFieldWithError(
              label: l10n.phoneNumberWithAst,
              controller: _controller.phoneController,
              textTheme: textTheme,
              colorScheme: colorScheme,
              error: _controller.phoneError,
              keyboard: TextInputType.phone,
              onChanged: (_) => _controller.validate(l10n),
            ),
          ],
        );
      case QrType.phone:
        return Column(
          children: [
            _buildTextFieldWithError(
              label: l10n.phoneNumberWithAst,
              controller: _controller.phoneController,
              textTheme: textTheme,
              colorScheme: colorScheme,
              error: _controller.phoneError,
              keyboard: TextInputType.phone,
              onChanged: (_) => _controller.validate(l10n),
            ),
          ],
        );
      case QrType.email:
        return Column(
          children: [
            _buildTextFieldWithError(
              label: l10n.emailWithAst,
              controller: _controller.emailController,
              textTheme: textTheme,
              colorScheme: colorScheme,
              error: _controller.emailError,
              keyboard: TextInputType.emailAddress,
              onChanged: (_) => _controller.validate(l10n),
            ),
          ],
        );
      case QrType.text:
        return Column(
          children: [
            TextField(
              controller: _controller.textController,
              maxLines: 3,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: _inputDecoration(l10n.content, colorScheme, textTheme).copyWith(
                errorText: _controller.textError,
                errorStyle: const TextStyle(fontWeight: FontWeight.w500),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste_rounded, color: SecureScanTheme.accentBlue),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      _controller.textController.text = data!.text!;
                      if (mounted) _controller.validate(AppLocalizations.of(context)!);
                    }
                  },
                ),
              ),
              onChanged: (_) => _controller.validate(l10n),
            ),
          ],
        );
      case QrType.calendar:
        return Column(
          children: [
             _buildTextFieldWithError(
              label: "${l10n.calendarEvent} *",
              controller: _controller.eventTitleController,
              textTheme: textTheme,
              colorScheme: colorScheme,
              error: _controller.eventTitleError,
              onChanged: (_) => _controller.validate(l10n),
            ),
            _buildTextFieldWithError(
              label: l10n.location,
              controller: _controller.eventLocationController,
              textTheme: textTheme,
              colorScheme: colorScheme,
              onChanged: (_) => _controller.validate(l10n),
            ),
            _buildTextFieldWithError(
              label: l10n.content,
              controller: _controller.eventDescController,
              textTheme: textTheme,
              colorScheme: colorScheme,
              maxLines: 3,
              onChanged: (_) => _controller.validate(l10n),
            ),
          ],
        );
      case QrType.location:
        return Column(
          children: [
            _buildTextFieldWithError(
              label: "Latitude *",
              controller: _controller.latController,
              textTheme: textTheme,
              colorScheme: colorScheme,
              error: _controller.latError,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _controller.validate(l10n),
            ),
            _buildTextFieldWithError(
              label: "Longitude *",
              controller: _controller.lngController,
              textTheme: textTheme,
              colorScheme: colorScheme,
              error: _controller.lngError,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _controller.validate(l10n),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  InputDecoration _inputDecoration(String label, ColorScheme colorScheme, TextTheme textTheme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SecureScanTheme.accentBlue, width: 1.5),
      ),
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _errorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 16),
      child: Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCreateButton(AppLocalizations l10n) {
    return Center(
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: SecureScanTheme.accentBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _handleGenerate,
          style: ElevatedButton.styleFrom(
            backgroundColor: SecureScanTheme.accentBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
          child: Text(
            l10n.createQr.toUpperCase(), 
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.0),
          ),
        ),
      ),
    );
  }

  Widget _buildQRResult(TextTheme textTheme, ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      key: const ValueKey('result'),
      children: [
        const SizedBox(height: 20),
        RepaintBoundary(
          key: _qrKey,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: _controller.qrData,
                  version: QrVersions.auto,
                  size: 250,
                  gapless: false,
                  errorCorrectionLevel: QrErrorCorrectLevel.Q,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
                // if (widget.selectedType == QrType.text) ...[
                //   const SizedBox(height: 12),
                //   Text(
                //     _controller.qrData.length > 50 ? '${_controller.qrData.substring(0, 50)}...' : _controller.qrData,
                //     style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
                //     textAlign: TextAlign.center,
                //   ),
                // ]
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),
        Text(
          l10n.qrCodeReady,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.onBackground),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.qrGeneratedSaved,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.6)),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _buildActionButton(l10n.share, Icons.share_rounded, _shareQR, colorScheme)),
            const SizedBox(width: 16),
            Expanded(child: _buildActionButton(l10n.download, Icons.download_rounded, _downloadQR, colorScheme)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _buildActionButton(l10n.edit, Icons.edit_rounded, () => _controller.setIsCreated(false), colorScheme)),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                l10n.backToMain, 
                Icons.home_rounded, 
                () => Navigator.pop(context), 
                colorScheme,
                isFullWidth: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BannerAdWidget(),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, ColorScheme colorScheme, {bool isFullWidth = false}) {
    return Container(
       decoration: BoxDecoration(
          boxShadow: isFullWidth ? [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
       ),
       child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFullWidth ? SecureScanTheme.accentBlue : colorScheme.surface,
          foregroundColor: isFullWidth ? Colors.white : colorScheme.onSurface,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: isFullWidth ? BorderSide.none : BorderSide(color: colorScheme.outline.withOpacity(0.1)),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _shareQR() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Small delay to ensure the widget is fully painted after animation
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(buffer);
        await Share.shareXFiles(
          [XFile(file.path)], 
          text: l10n.sharePromoText('https://play.google.com/store/apps/details?id=com.securescan.securescan')
        );
      }
    } catch (e) {
      debugPrint("Error sharing QR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to share QR: $e")),
        );
      }
    }
  }

  Future<void> _downloadQR() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      setState(() => _controller.setIsCreated(true)); // Just to ensure UI state
      
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        await Gal.putImageBytes(buffer, album: 'SecureScanner');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.qrSavedToGallery),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error downloading QR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save QR: $e")),
        );
      }
    }
  }

  Widget _buildTextFieldWithError({
    required String label,
    required TextEditingController controller,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    String? error,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: _inputDecoration(label, colorScheme, textTheme).copyWith(
            errorText: error,
            errorStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
