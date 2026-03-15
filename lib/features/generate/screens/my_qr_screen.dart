import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:securescan/l10n/app_localizations.dart';
import 'package:securescan/themes.dart';

class MyQrScreen extends StatefulWidget {
  const MyQrScreen({super.key});

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  static const String _prefsContactKey = 'my_qr_contact_json';
  static const String _prefsQrDataKey = 'my_qr_contact_qr_data';

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  String? _qrData;
  Map<String, String>? _contact;

  @override
  void initState() {
    super.initState();
    _loadSavedContact();
  }

  Future<void> _loadSavedContact() async {
    final prefs = await SharedPreferences.getInstance();
    final contactJson = prefs.getString(_prefsContactKey);
    final qrData = prefs.getString(_prefsQrDataKey);

    if (contactJson != null && qrData != null) {
      final Map<String, dynamic> decoded = jsonDecode(contactJson);
      _contact = decoded.map((k, v) => MapEntry(k, v.toString()));
      _qrData = qrData;

      _nameController.text = _contact?['name'] ?? '';
      _phoneController.text = _contact?['phone'] ?? '';
      _emailController.text = _contact?['email'] ?? '';
      _companyController.text = _contact?['company'] ?? '';

      _isEditing = false;
    } else {
      // No contact yet: show form
      _isEditing = true;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildVCard(Map<String, String> contact) {
    final name = contact['name'] ?? '';
    final phone = contact['phone'] ?? '';
    final email = contact['email'] ?? '';
    final company = contact['company'] ?? '';

    // Simple vCard 3.0 payload
    return '''
BEGIN:VCARD
VERSION:3.0
N:$name;
FN:$name
TEL;TYPE=CELL:$phone
EMAIL;TYPE=INTERNET:$email
ORG:$company
END:VCARD
'''.trim();
  }

  Future<void> _saveContact() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final company = _companyController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.namePhoneRequired),
        ),
      );
      return;
    }

    final contact = <String, String>{
      'name': name,
      'phone': phone,
      'email': email,
      'company': company,
    };

    final qrData = _buildVCard(contact);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsContactKey, jsonEncode(contact));
    await prefs.setString(_prefsQrDataKey, qrData);

    setState(() {
      _contact = contact;
      _qrData = qrData;
      _isEditing = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myQr),
        actions: [
          if (!_isLoading && !_isEditing && _contact != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.editContact,
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(20),
          child: _isEditing ? _buildEditForm(Theme.of(context).textTheme) : _buildQrView(Theme.of(context).textTheme),
        ),
      ),
    );
  }
  Widget _buildEditForm(TextTheme textTheme) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.yourContactQr,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
             ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingMyQrDesc,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.nameWithAst,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneWithAst,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.email,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _companyController,
            decoration: InputDecoration(
              labelText: l10n.company,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveContact,
              child: Text(l10n.saveAndGenerate, style: const TextStyle(color: Colors.white),),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(TextTheme textTheme) {
    final l10n = AppLocalizations.of(context)!;
    if (_qrData == null || _contact == null) {
      // Fallback: if something got corrupted, go back to edit mode
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.noContactQrFound),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: Text(l10n.createNow),
            ),
          ],
        ),
      );
    }

    final name = _contact!['name'] ?? '';
    final phone = _contact!['phone'] ?? '';
    final email = _contact!['email'] ?? '';
    final company = _contact!['company'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.yourContactQr,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // QR code
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: RepaintBoundary(
              key: _qrKey,
              child: QrImageView(
                data: _qrData!,
                version: QrVersions.auto,
                size: 230,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Contact details under QR
        Card(
          elevation: 0,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.shade900 
              : Colors.grey.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
                if (company.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    company,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const Spacer(),

        // Actions Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloadQR,
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: Text(l10n.download.toUpperCase(), style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SecureScanTheme.accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareQR,
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: Text(l10n.share.toUpperCase(), style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SecureScanTheme.accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            icon: const Icon(Icons.edit),
            label: Text(l10n.editContact),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: SecureScanTheme.accentBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  final GlobalKey _qrKey = GlobalKey();

  Future<void> _downloadQR() async {
    try {
      final boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'my_qr_$timestamp.png';

      // Save to gallery
      await Gal.putImageBytes(pngBytes, album: 'SecureScanner');

      if (mounted) {
        _showSuccessDialog(l10n: AppLocalizations.of(context)!, filename: filename);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _shareQR() async {
    try {
      final boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/shared_qr.png').create();
      await file.writeAsBytes(pngBytes);
      
      await Share.shareXFiles([XFile(file.path)], text: AppLocalizations.of(context)!.myGeneratedQr);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _showSuccessDialog({required AppLocalizations l10n, required String filename}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 4),
            Text("Download Successful",style: TextStyle(fontSize: 14),),
          ],
        ),
        content: Text(l10n.qrSaved(filename)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
